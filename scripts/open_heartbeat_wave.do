# Questa waveform setup for tb_heartbeat_monitor.
# The testbench remains self-checking; this waveform is for inspection and
# learning, not the primary PASS/FAIL mechanism.

view wave
delete wave *

add wave -divider {Testbench inputs}
add wave -label clk            sim:/tb_heartbeat_monitor/clk
add wave -label rst_n          sim:/tb_heartbeat_monitor/rst_n
add wave -label heartbeat      sim:/tb_heartbeat_monitor/heartbeat
add wave -label clear_timeout  sim:/tb_heartbeat_monitor/clear_timeout

add wave -divider {DUT state}
add wave -label elapsed_cycles -radix unsigned sim:/tb_heartbeat_monitor/dut/elapsed_cycles
add wave -label timeout        sim:/tb_heartbeat_monitor/timeout

add wave -divider {Testbench status}
add wave -label checks         -radix unsigned sim:/tb_heartbeat_monitor/checks
add wave -label errors         -radix unsigned sim:/tb_heartbeat_monitor/errors

run -all
wave zoom full
