# =============================================================================
# ee8350 — build system
# =============================================================================

# Basic Configuration
TOP_MODULE ?= aes_tb
UVM_TEST   ?= aes_base_test
BUILD_DIR  ?= build
VCS_DIR    := $(BUILD_DIR)/vcs/$(TOP_MODULE)
VL_DIR     := $(BUILD_DIR)/vl/$(TOP_MODULE)

# Tooling Configuration
VCS        ?= vcs
VERILATOR  ?= verilator
VCF        ?= vcf
VCF_TCL    ?= scripts/run_hector.tcl

# File Decection for HDL Source and HVL Source
HDL_SOURCE := $(shell find src/hdl -type f \( -name '*.sv' -o -name '*.v' \) 2>/dev/null)
HVL_SOURCE := $(shell find src/hvl -type f \( -name '*.sv' -o -name '*.v' \) 2>/dev/null)

# Flags for running with different toolchains
UVM_VCS_ARGS       := -kdb -full64 -cm line+cond+fsm -Mupdate +v2k -sverilog \
					  -timescale=1ns/10ps +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv \
					  ${UVM_HOME}/src/dpi/uvm_dpi.cc -CFLAGS -DVCS -l ${VCS_DIR}/compile.log \
					  -debug_all -Mdir=$(VCS_DIR)/csrc -o $(VCS_DIR)/simv
UVM_VERILATOR_ARGS := --binary --build -j 16 --timing --timescale 1ns/10ps --output-split 5000 \
					  --output-split-cfuncs 500 -MAKEFLAGS "OBJCACHE=ccache OPT_FAST=-O0 \
					  OPT_SLOW=-O0" -LDFLAGS "-fuse-ld=lld" -I${UVM_HOME}/src \
					  ${UVM_HOME}/src/uvm.sv ${UVM_HOME}/src/dpi/uvm_dpi.cc \
					  --Mdir $(VL_DIR)/obj_dir -Wno-fatal

.DEFAULT_GOAL := sim-vl
.PHONY: build-vcs sim-vcs build-vl sim-vl vcf gen-formal gen-dpi clean

# ----- VCS -------------------------------------------------------------------

build-vcs: $(HVL_SOURCE) $(HDL_SOURCE)
	@mkdir -p $(VCS_DIR)
	$(VCS) $(UVM_VCS_ARGS) $(HVL_SOURCE) $(HDL_SOURCE) -top $(TOP_MODULE)

sim-vcs: build-vcs
	./$(VCS_DIR)/simv +UVM_TESTNAME=$(UVM_TEST) -l $(VCS_DIR)/$(UVM_TEST).log

# ----- Verilator -------------------------------------------------------------

build-vl: $(HVL_SOURCE) $(HDL_SOURCE)
	@mkdir -p $(VL_DIR)
	$(VERILATOR) $(UVM_VERILATOR_ARGS) $(HVL_SOURCE) $(HDL_SOURCE) --top-module $(TOP_MODULE)

sim-vl: build-vl
	./$(VL_DIR)/obj_dir/V$(TOP_MODULE) +UVM_TESTNAME=$(UVM_TEST) | tee $(VL_DIR)/$(UVM_TEST).log

# ----- VCF / HECTOR ----------------------------------------------------------

vcf:
	@mkdir -p $(BUILD_DIR)/vcf
	$(VCF) -fmode DPV -batch -f $(VCF_TCL) | tee $(BUILD_DIR)/vcf/vcf.log

# ----- Codegen ---------------------------------------------------------------

gen-formal:
	cd src/model && cd "$$(pwd -P)" && matlab -batch "gen_formal"

gen-dpi:
	cd src/model && cd "$$(pwd -P)" && matlab -batch "gen_dpi"

# ----- Cleanup ---------------------------------------------------------------

clean:
	@case "$(BUILD_DIR)" in \
		""|/|.|..|./) echo "Error: Refusing to rm -rf '$(BUILD_DIR)'" >&2; exit 1 ;; \
	esac
	rm -rf "$(BUILD_DIR)" *.vcd
