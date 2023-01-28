vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/simulation/assembler_util.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/simulation/top_tb.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/cpu.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/mem_cntrl.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/serial_driver.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/system_init.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/cpu/alu.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/cpu/core.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/cpu/reg_file.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/mem_cntrl/mem_driver.sv
vlog -reportprogress 30 -work work C:/Users/jalun/Desktop/Computer_Proj_IPs/system/src/top/mem_cntrl/segment_driver.sv
vsim -gui work.top_tb -t ns

add wave -position insertpoint -radix hex \
sim:/top_tb/TOP/CPU/CORE/*

add wave -position insertpoint -radix hex \
sim:/top_tb/TOP/CPU/REG/reg_file

add wave -position insertpoint -radix hex \
sim:/top_tb/TOP/MEM_CTRL/MEM_DRV/*

run 100ms