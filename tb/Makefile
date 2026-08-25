SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES += $(PWD)/../src/control_FSM.sv
VERILOG_SOURCES += $(PWD)/../src/udp_header_parser.sv
VERILOG_SOURCES += $(PWD)/../src/payload_forwarder.sv
VERILOG_SOURCES += $(PWD)/../src/udp_parser_top.sv

TOPLEVEL = udp_parser_top
MODULE = test_udp_parser

COMPILE_ARGS += -g2012

include $(shell cocotb-config --makefiles)/Makefile.sim
