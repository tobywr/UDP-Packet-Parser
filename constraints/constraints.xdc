create_clock -period 5 -name clk [get_ports clk]
set_clock_uncertainty 0.035 [get_clocks clk]
set_false_path -from [get_ports rst_n]

set_input_delay  -clock clk 2.000 [get_ports {s_axis_tdata[*] s_axis_tvalid s_axis_tuser m_axis_tready}]
set_output_delay -clock clk 2.000 [get_ports {m_axis_tdata[*] m_axis_tvalid m_axis_tlast s_axis_tready src_port[*] dst_port[*] length[*] header_done}]
set_false_path -from [get_ports target_port[*]]