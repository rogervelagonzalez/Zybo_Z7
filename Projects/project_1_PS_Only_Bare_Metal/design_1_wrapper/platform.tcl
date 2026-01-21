# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\ZYBO_Z7\Projects\project_1_PS_Only_Bare_Metal\design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\ZYBO_Z7\Projects\project_1_PS_Only_Bare_Metal\design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {design_1_wrapper}\
-hw {C:\Users\rvelago\ZYBO_Z7\Projects\project_1_PS_Only_Bare_Metal\design_1_wrapper.xsa}\
-out {C:/Users/rvelago/ZYBO_Z7/Projects/project_1_PS_Only_Bare_Metal}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {design_1_wrapper}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
