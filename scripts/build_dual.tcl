set root [file normalize [file join [file dirname [info script]] ..]]
cd [file join $root dual_audio]
set_device -name GW1N-9C GW1N-UV9EQ144C6/I5
add_file [file join $root src top_dual.v]
add_file [file join $root src performance_ctrl_usb.v]
add_file [file join $root src arp_engine.v]
add_file [file join $root src event_recorder_usb.v]
add_file [file join $root src synth_core.v]
add_file [file join $root src waveform.v]
add_file [file join $root src mixer_pipe.v]
add_file [file join $root src mixer.v]
add_file [file join $root src pcm_decimator.v]
add_file [file join $root src pcm_packetizer.v]
add_file [file join $root src uart_tx.v]
add_file [file join $root constraints f1_usb.cst]
add_file [file join $root constraints f1.sdc]
set_option -top_module top_dual
set_option -output_base_name f1_dual
set_option -use_sspi_as_gpio 1
set_option -bit_security 0
set_option -gen_text_timing_rpt 1
run all
