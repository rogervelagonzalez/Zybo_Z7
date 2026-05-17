# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\rvelago\Zybo_Z7\axi_gpio\axi_gpio\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\rvelago\Zybo_Z7\axi_gpio\axi_gpio\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {axi_gpio}\
-hw {C:\Users\rvelago\Zybo_Z7\axi_gpio\design_1_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/rvelago/Zybo_Z7/axi_gpio}

platform write
platform generate -domains 
platform active {axi_gpio}
platform generate
platform clean
platform generate
