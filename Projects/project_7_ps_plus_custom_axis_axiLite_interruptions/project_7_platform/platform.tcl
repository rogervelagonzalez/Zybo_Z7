# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\Zybo_Z7\Projects\project_7_ps_plus_custom_axis_axiLite_interruptions\project_7_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\Zybo_Z7\Projects\project_7_ps_plus_custom_axis_axiLite_interruptions\project_7_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {project_7_platform}\
-hw {R:\project_7_ps_plus_custom_axis_axiLite_interruptions\design_1_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/rvelago/Zybo_Z7/Projects/project_7_ps_plus_custom_axis_axiLite_interruptions}

platform write
platform generate -domains 
platform active {project_7_platform}
platform generate
platform generate -domains zynq_fsbl 
platform generate -domains standalone_domain,zynq_fsbl 
