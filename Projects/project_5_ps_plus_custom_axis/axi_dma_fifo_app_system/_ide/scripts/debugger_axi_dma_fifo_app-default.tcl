# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\rvelago\Zybo_Z7\axi_dma_fifo\axi_dma_fifo_app_system\_ide\scripts\debugger_axi_dma_fifo_app-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\rvelago\Zybo_Z7\axi_dma_fifo\axi_dma_fifo_app_system\_ide\scripts\debugger_axi_dma_fifo_app-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent Zybo Z7 210351B0FC3FA" && level==0 && jtag_device_ctx=="jsn-Zybo Z7-210351B0FC3FA-13722093-0"}
fpga -file C:/Users/rvelago/Zybo_Z7/axi_dma_fifo/axi_dma_fifo_app/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/Users/rvelago/Zybo_Z7/axi_dma_fifo/axi_dma_fifo_platform/export/axi_dma_fifo_platform/hw/design_1_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source C:/Users/rvelago/Zybo_Z7/axi_dma_fifo/axi_dma_fifo_app/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow C:/Users/rvelago/Zybo_Z7/axi_dma_fifo/axi_dma_fifo_app/Debug/axi_dma_fifo_app.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
