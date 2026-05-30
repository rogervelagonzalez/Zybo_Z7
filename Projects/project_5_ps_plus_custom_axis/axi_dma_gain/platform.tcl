# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\Zybo_Z7\Projects\project_5_ps_plus_custom_axis\axi_dma_gain\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\Zybo_Z7\Projects\project_5_ps_plus_custom_axis\axi_dma_gain\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {axi_dma_gain}\
-hw {C:\Users\rvelago\Zybo_Z7\Projects\project_5_ps_plus_custom_axis\design_1_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/rvelago/Zybo_Z7/Projects/project_5_ps_plus_custom_axis}

platform write
platform generate -domains 
platform active {axi_dma_gain}
platform generate
