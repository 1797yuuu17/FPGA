create_clock -name clk_50m -period 20 [get_ports {clk_50m}]
# Gowin does not support user virtual clocks. Use a stricter 10ns half-cycle
# output budget relative to the 50MHz reference falling edge. RTL data changes
# on DAC falling edges, 40ns before actual capture; check that relation in TB.
# 3PD5651E setup=2ns, hold=1.5ns, with provisional 3ns interface skew budget.
set_output_delay -clock clk_50m -clock_fall -max 5.0 [get_ports {dac_data[*]}]
set_output_delay -clock clk_50m -clock_fall -min -4.5 [get_ports {dac_data[*]}]
# Data can change only once per 4 master cycles; actual capture is 40ns later.
# Two-cycle setup checks a stricter 30ns surrogate edge (10ns extra margin).
set_multicycle_path 2 -setup -to [get_ports {dac_data[*]}]
set_multicycle_path 1 -hold -to [get_ports {dac_data[*]}]
