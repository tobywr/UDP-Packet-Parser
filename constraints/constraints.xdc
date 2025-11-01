create_clock -period 5 -name clk [get_ports clk]
set_clock_uncertainty 0.035 [get_clocks clk]