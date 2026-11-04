onerror {quit -code 1 -f}
if {![file exists sim/work]} {vlib sim/work}
vmap work sim/work
eval vlog -sv [glob ../src/*.v] [glob ../tb/*.sv]
if {![info exists TEST]} {set TEST tb_dual_audio}
vsim -voptargs=+acc work.$TEST
onfinish exit
run -all
quit -code 0 -f
