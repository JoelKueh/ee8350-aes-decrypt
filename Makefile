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
VCF_TCL    ?= $(realpath scripts/run_hector.tcl)

# AES Mode Configuration
AES_MODE   ?= 128
export AES_MODE

# Source Directory Configuration
SPC_DIR := $(realpath src/model/codegen/lib/aes_$(AES_MODE))
DPV_DIR := $(realpath src/dpv)
FPV_DIR := $(realpath src/fpv)
HDL_DIR := $(realpath src/hdl)
HVL_DIR := $(realpath src/hvl)

# Source Filelist Configuration
SPC_SRCS := $(SPC_DIR)/Encrypt.cpp \
			$(SPC_DIR)/Decrypt.cpp \
			$(SPC_DIR)/KeyExpand.cpp \
			$(SPC_DIR)/SBox.cpp \
			$(SPC_DIR)/aes_128_initialize.cpp \
			$(SPC_DIR)/aes_128_terminate.cpp \
			$(SPC_DIR)/circshift.cpp
DPV_SRCS := $(DPV_DIR)/aes_hector_top.cpp
FPV_SRCS :=
HDL_SRCS := $(HDL_DIR)/generic/generic_muxfx.v \
            $(HDL_DIR)/gfmul.sv \
            $(HDL_DIR)/Sbox.sv \
            $(HDL_DIR)/InvSbox.sv \
            $(HDL_DIR)/RotWord.sv \
            $(HDL_DIR)/SubWord.sv \
            $(HDL_DIR)/InvAddRoundKey.sv \
            $(HDL_DIR)/InvShiftRows.sv \
            $(HDL_DIR)/InvSubBytes.sv \
            $(HDL_DIR)/InvMixCol_slice.sv \
            $(HDL_DIR)/InvMixColumns.sv \
            $(HDL_DIR)/KschBuffer.sv \
            $(HDL_DIR)/KeyExpand128.sv \
            $(HDL_DIR)/KeyExpand192.sv \
            $(HDL_DIR)/KeyExpand256.sv \
            $(HDL_DIR)/decrypt.sv \
            $(HDL_DIR)/aes_decrypt$(AES_MODE).sv
HVL_SRCS := $(HVL_DIR)/bfms/ksch_buffer_if.sv \
			$(HVL_DIR)/bfms/rv_if.sv \
			$(HVL_DIR)/tbs/aes_core_adapter.sv \
			$(HVL_DIR)/tbs/aes_tb.sv

# Flags for running with different toolchains
UVM_VCS_ARGS       := -kdb -full64 -cm line+cond+fsm -Mupdate +v2k -sverilog \
					  -timescale=1ns/10ps +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv \
					  ${UVM_HOME}/src/dpi/uvm_dpi.cc -CFLAGS -DVCS -l ${VCS_DIR}/compile.log \
					  -debug_access+all -Mdir=$(VCS_DIR)/csrc -o $(VCS_DIR)/simv
UVM_VERILATOR_ARGS := --binary --build -j 16 --timing --timescale 1ns/10ps --output-split 5000 \
					  --output-split-cfuncs 500 -MAKEFLAGS "OBJCACHE=ccache OPT_FAST=-O0 \
					  OPT_SLOW=-O0" -LDFLAGS "-fuse-ld=lld" -I${UVM_HOME}/src \
					  ${UVM_HOME}/src/uvm.sv ${UVM_HOME}/src/dpi/uvm_dpi.cc \
					  --Mdir $(VL_DIR)/obj_dir -Wno-fatal

.DEFAULT_GOAL := sim-vl
.PHONY: build-vcs sim-vcs build-vl sim-vl dpv gen-formal gen-dpi clean

# ----- VCS -------------------------------------------------------------------

build-vcs: $(HVL_SRCS) $(HDL_SRCS)
	@mkdir -p $(VCS_DIR)
	$(VCS) $(UVM_VCS_ARGS) $(HVL_SRCS) $(HDL_SRCS) -top $(TOP_MODULE)

sim-vcs: build-vcs
	./$(VCS_DIR)/simv +UVM_TESTNAME=$(UVM_TEST) -l $(VCS_DIR)/$(UVM_TEST).log

# ----- Verilator -------------------------------------------------------------

build-vl: $(HVL_SRCS) $(HDL_SRCS)
	@mkdir -p $(VL_DIR)
	$(VERILATOR) $(UVM_VERILATOR_ARGS) $(HDL_SRCS) $(HVL_SRCS) --top-module $(TOP_MODULE)

sim-vl: build-vl
	./$(VL_DIR)/obj_dir/V$(TOP_MODULE) +UVM_TESTNAME=$(UVM_TEST) | tee $(VL_DIR)/$(UVM_TEST).log

# ----- VCF / HECTOR ----------------------------------------------------------

dpv:
	@mkdir -p $(BUILD_DIR)/vcf
	SPC_DIR="$(SPC_DIR)" \
	SPC_SRCS="$(SPC_SRCS)" \
	DPV_SRCS="$(DPV_SRCS)" \
	HDL_SRCS="$(HDL_SRCS)" \
	$(VCF) -fmode DPV -batch -f $(VCF_TCL) | tee $(BUILD_DIR)/vcf/vcf.log

# ----- Codegen ---------------------------------------------------------------

gen-formal:
	cd src/model && cd "$$(pwd -P)" && QT_QPA_PLATFORM=offscreen matlab -batch "gen_formal"

gen-dpi:
	cd src/model && cd "$$(pwd -P)" && QT_QPA_PLATFORM=offscreen matlab -batch "gen_dpi"

# ----- Cleanup ---------------------------------------------------------------

clean:
	@case "$(BUILD_DIR)" in \
		""|/|.|..|./) echo "Error: Refusing to rm -rf '$(BUILD_DIR)'" >&2; exit 1 ;; \
	esac
	rm -rf "$(BUILD_DIR)" *.vcd
