vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/mem_cntrl/src/mem_cntrl.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/mem_cntrl/src/segment_driver.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/mem_cntrl/src/top.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/mem_cntrl/src/top_sim.sv
vsim -gui work.top_sim -t ns

add wave -position insertpoint -radix hex \
sim:/top_sim/TOP/*

add wave -position insertpoint -radix hex \
sim:/top_sim/TOP/MEM/*

run 500us