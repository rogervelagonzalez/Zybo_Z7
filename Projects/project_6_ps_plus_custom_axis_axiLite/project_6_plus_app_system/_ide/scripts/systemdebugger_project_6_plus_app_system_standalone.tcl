# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\rvelago\Zybo_Z7\Projects\project_6_ps_plus_custom_axis_axiLite\project_6_plus_app_system\_ide\scripts\systemdebugger_project_6_plus_app_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\rvelago\Zybo_Z7\Projects\project_6_ps_plus_custom_axis_axiLite\project_6_plus_app_system\_ide\scripts\systemdebugger_project_6_plus_app_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent Zybo Z7 210351B0FC3FA" && level==0 && jtag_device_ctx=="jsn-Zybo Z7-210351B0FC3FA-13722093-0"}
fpga -file C:/Users/rvelago/Zybo_Z7/Projects/project_6_ps_plus_custom_axis_axiLite/project_6_plus_app/_ide/bitstream/design_1_wrapper_05072026.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/Users/rvelago/Zybo_Z7/Projects/project_6_ps_plus_custom_axis_axiLite/project_6_platform_plus/export/project_6_platform_plus/hw/design_1_wrapper_05072026.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source C:/Users/rvelago/Zybo_Z7/Projects/project_6_ps_plus_custom_axis_axiLite/project_6_plus_app/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow C:/Users/rvelago/Zybo_Z7/Projects/project_6_ps_plus_custom_axis_axiLite/project_6_plus_app/Debug/project_6_plus_app.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
