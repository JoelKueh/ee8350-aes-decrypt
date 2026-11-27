# =============================================================================
# Synopsys VCF DPV (HECTOR) Runner for AES Encryption Core
# Usage:
# 	PROOF={Decrypt/KeyExpand} AES_MODE={128/192/256} \
# 		vcf -fmode DPV -batch -f scripts/run_hector.tcl
# =============================================================================

set SPC_DIR  $::env(SPC_DIR)
set SPC_SRCS $::env(SPC_SRCS)
set DPV_SRCS $::env(DPV_SRCS)
set HDL_SRCS $::env(HDL_SRCS)
set AES_MODE $::env(AES_MODE)

set AES_TOP  "aes_decrypt${AES_MODE}"
set OUT_DIR  "build/vcf"
file mkdir $OUT_DIR

# Map AES_MODE to the particular width cycle parameters
if {$AES_MODE eq "128"} {
	set KEY_BYTES 16
	set KEY_BUFFER_BYTES 176

	set KT_CYCLE 2;  # Cycle that key text is presented (just after reset)
	set CT_CYCLE 13; # Cycle that cipher text is presented (after key decoded)
	set PT_CYCLE 24; # Cycle that plain text is ready at the output
} elseif {$AES_MODE eq "192"} {
	set KEY_BYTES 24
	set KEY_BUFFER_BYTES 208

	set KT_CYCLE 2
	set CT_CYCLE 15
	set PT_CYCLE 28
} elseif {$AES_MODE eq "256"} {
	set KEY_BYTES 32
	set KEY_BUFFER_BYTES 240

	set KT_CYCLE 2
	set CT_CYCLE 17
	set PT_CYCLE 32
} else {
	error "Unsupported AES_MODE=$AES_MODE (use 128, 192, or 256)"
}

# HECTOR uses number of edges and not cycles.
proc cyc {n} { expr {2 * $n - 1} }

proc compile_spec {} {
	create_design -name spec -top hector_wrapper
	cppan -m64 -I$::SPC_DIR -DAES_KEY_BYTES=$::KEY_BYTES -DAES_RK_BYTES=$::KEY_BUFFER_BYTES \
		   {*}$::SPC_SRCS {*}$::DPV_SRCS
	compile_design spec
}

proc compile_impl {} {
	create_design -name impl -top $::AES_TOP -clock clk -reset rst -posReset
	vcs -sverilog {*}$::HDL_SRCS
	compile_design impl
}

proc ual {} {
	# Synchronous reset, high on cycle 0 and low on all other cycles.
	assume impl.rst([cyc 1]) == 1
	for {set c 2} {$c <= $::PT_CYCLE} {incr c} {
		assume impl.rst([cyc $c]) == 0
	}

	# Drive kt_vld and ct_vld for 1 cycle, low everywhere else
	for {set c 1} {$c <= $::PT_CYCLE} {incr c} {
		assume impl.kt_vld([cyc $c]) == [expr {$c == $::KT_CYCLE ? 1 : 0}];
		assume impl.ct_vld([cyc $c]) == [expr {$c == $::CT_CYCLE ? 1 : 0}];
	}

	# Assume matching inputs on the proper cycle
	assume spec.K(1) == impl.kt([cyc $::KT_CYCLE])
	assume spec.C(1) == impl.ct([cyc $::CT_CYCLE])

	# Sanity check lemmas for accepted inputs and valid output
	lemma kt_accepted = (impl.kt_rdy([cyc $::KT_CYCLE]) == 1)
	lemma ct_accepted = (impl.ct_rdy([cyc $::CT_CYCLE]) == 1)
	lemma pt_valid    = (impl.pt_vld([cyc $::PT_CYCLE]) == 1)

	# Most important lemma for equivalent plaintext
	lemma pt_eq = (spec.P(1) == impl.pt([cyc $::PT_CYCLE]))
}

set_user_assumes_lemmas_procedure "ual"

compile_spec
compile_impl
compose

solveNB p1
proofwait

listproof > "$OUT_DIR/proof_decrypt${AES_MODE}.txt"
exit
