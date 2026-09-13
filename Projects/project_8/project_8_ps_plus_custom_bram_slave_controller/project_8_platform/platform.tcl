# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\Zybo_Z7\Projects\project_8\project_8_ps_plus_custom_bram_slave_controller\project_8_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\Zybo_Z7\Projects\project_8\project_8_ps_plus_custom_bram_slave_controller\project_8_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {project_8_platform}\
-hw {Z:\project_8\project_8_ps_plus_custom_bram_slave_controller\design_1_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/rvelago/Zybo_Z7/Projects/project_8/project_8_ps_plus_custom_bram_slave_controller}

platform write
platform generate -domains 
platform active {project_8_platform}
platform generate
