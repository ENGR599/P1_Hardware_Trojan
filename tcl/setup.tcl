
set MYFILE [file normalize [info script]]
set MYDIR  [file dirname ${MYFILE}]
set BASEDIR ${MYDIR}/../
set SRCDIR ${MYDIR}/../vsrc/
set TESTDIR ${MYDIR}/../vtests/
set XDCDIR ${MYDIR}/../xdc/

create_project -force vivado.xpr ${BASEDIR}/vivado -part xc7a35ticpg236-1L

# add source files
add_files [glob ${SRCDIR}/*.v]
add_files [glob ${SRCDIR}/*.sv]

#set the top for synthesis
set_property top top [current_fileset]

# add testbenches
create_fileset -simset sim_wide_uart
add_files -fileset sim_wide_uart [glob ${TESTDIR}/wide_uart_tb.sv]
set_property top wide_uart_tb [get_filesets sim_wide_uart]

create_fileset -simset sim_top
add_files -fileset sim_top [glob ${TESTDIR}/top_tb.sv]
set_property top top_tb [get_filesets sim_top]

#create_fileset -simset sim_ctrlr
#add_files -fileset sim_ctrlr [glob ${TESTDIR}/ctrlr_tb.sv]
#set_property top ctrlr_tb [get_filesets sim_ctrlr]

# set active simulation
current_fileset -simset [ get_filesets sim_top]

# add constraints
add_files -fileset constrs_1 ${XDCDIR}/Basys3_Master.xdc

# set all *.sv to SystemVerilog mode
set_property file_type SystemVerilog [get_files *.sv]
set_property file_type SystemVerilog [get_files *.v]

#make sims run longer by default
set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_*]
