
# =============================================================================
# Synopsys VCF DPV (HECTOR) Runner for AES Encryption Core
# Usage:
# 	PROOF={Decrypt/KeyExpand} AES_MODE={128/192/256} \
# 		vcf -fmode DPV -batch -f scripts/run_hector.tcl
# =============================================================================

# Fetch proof mode from the environment
# set PROOF    [expr {[info exists env(PROOF)}]   ? $env(PROOF)    : "Decrypt"}]
set AES_MODE [expr {[info exists env(AES_MODE)] ? $env(AES_MODE) : "128"}]

# Set TCL variables for our particular run configuration
set SPEC_DIR    "src/model/codegen/lib/aes_${AES_MODE}"
set WRAPPER_CPP "src/formal/aes_hector_top.cpp"
set OUT_DIR     "build/vcf"
file mkdir $OUT_DIR

set RTL_MODEL   "src/hdl/aes_decrypt${AES_MODE}.sv"
set AES_TOP     "aes_decrypt${AES_MODE}"

# Map AES_MODE to the particular width and round count parameters
if {$AES_MODE eq "128"} {
	set KEY_BYTES 16
	set KEY_BUFFER_BYTES 176
} elseif {$AES_MODE eq "192"} {
	set KEY_BYTES 16
	set KEY_BUFFER_BYTES 176
} elseif {$AES_MODE eq "256"} {
	set KEY_BYTES 16
	set KEY_BUFFER_BYTES 176
} else {
	error "Unsupported AES_MODE=$AES_MODE (use 128, 192, or 256)"
}

# TODO: Figure out this nocompliain business (you will probably have to hardcode the filelist)
# Set sources for RTL and CPP
set CPP_SRC [glob -nocomplain $CODEGEN_DIR/*.cpp]
set HDL_SRC [glob -nocomplain src/hdl/*.sv src/hdl/**/*.sv]

proc compile_spec {} {
	create_design -name spec -top hector_wrapper
	cppan -I$::SPEC_DIR -DAES_KEY_BYTES=$::KEY_BYTES -DAES_RK_BYTES=$::KEY_BUFFER_BYTES \
			$::WRAPPER_CPP {*}$::CPP_SRCS
	compile_design spec
}

proc compile_impl {} {
	create_design -name impl -top $::AES_TOP -clock clk -reset rst -posReset
	vcs -sverilog {*}$HDL_SRC
	compile_design impl
}

proc ual {} {
	assume impl.rst_n(1) 
}
