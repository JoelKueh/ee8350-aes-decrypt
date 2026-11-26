# =============================================================================
# ee8350 — build system
# =============================================================================

# Basic Configuration
TOP_MODULE  ?= aes_tb
DESIGN_NAME ?= $(TOP_MODULE)
BUILD_DIR   ?= build
SYNTH_DIR   ?= synth
VCS         ?= vcs
VERILATOR   ?= verilator
REMOTE      ?= vlsi
REMOTE_DIR  ?= /home/kuehn348/src/ee8350/aes-decode-remote

# Tool Auto Detection For Remote Runs
HAS_VCS       := $(shell command -v $(VCS) 2>/dev/null)
HAS_VCF       := $(shell command -v $(VCF) 2>/dev/null)
HAS_VERILATOR := $(shell command -v $(VERILATOR) 2>/dev/null)

# File Decection for HDL Source and HVL Source
HDL_SOURCE := $(shell find src/hdl -type f \( -name '*.sv' -o -name '*.v' \) 2>/dev/null)
HVL_SOURCE := $(shell find src/hvl -type f \( -name '*.sv' -o -name '*.v' \) 2>/dev/null)

# Flags for running with different toolchains
UVM_VCS_ARGS       := vcs -kdb -full64 -cm line+cond+fsm -Mupdate +v2k -sverilog \
					  -timescale=1ns/10ps +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv \
					  ${UVM_HOME}/src/dpi/uvm_dpi.cc -CFLAGS -DVCS -l compile.log -debug_all
UVM_VERILATOR_ARGS := --binary --build -j 16 --timing --timescale 1ns/10ps --output-split 5000 \
					  --output-split-cfuncs 500 -MAKEFLAGS "OBJCACHE=ccache OPT_FAST=-O0 \
					  OPT_SLOW=-O0" -LDFLAGS "-fuse-ld=lld" -I${UVM_HOME}/src \
					  ${UVM_HOME}/src/uvm.sv ${UVM_HOME}/src/dpi/uvm_dpi.cc \
                      --Mdir $(BUILD_DIR)/obj_dir -Wno-fatal


# ----- Build -----------------------------------------------------------------

.DEFAULT_GOAL := all
all: build

build: $(HVL_SOURCE) $(HDL_SOURCE)
	@mkdir -p build
	@cd $(BUILD_DIR)
	$(VCS) $(VCS_FLAGS) $(HVL_SOURCE) $(HDL_SOURCE) -top $(TOP_MODULE)
	@cd ../

clean:
	rm -rf $(BUILD_DIR) $(FILELIST) *.vcd
