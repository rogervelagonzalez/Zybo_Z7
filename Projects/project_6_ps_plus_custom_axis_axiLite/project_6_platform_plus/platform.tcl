# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\Zybo_Z7\Projects\project_6_ps_plus_custom_axis_axiLite\project_6_platform_plus\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\Zybo_Z7\Projects\project_6_ps_plus_custom_axis_axiLite\project_6_platform_plus\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {project_6_platform_plus}\
-hw {C:\Users\rvelago\Zybo_Z7\Projects\project_6_ps_plus_custom_axis_axiLite\design_1_wrapper_05072026.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/rvelago/Zybo_Z7/Projects/project_6_ps_plus_custom_axis_axiLite}

platform write
platform generate -domains 
platform active {project_6_platform_plus}
platform generate
