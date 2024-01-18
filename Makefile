SHELL 		:= /bin/bash

#https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
BASE_DIR 	:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

NUM_CORES 	:= 2

vivado/vivado.xpr: tcl/setup.tcl
	set -o pipefail && vivado -mode batch -source tcl/setup.tcl | tee setup.log	

.PHONY:  setup
setup:  vivado/vivado.xpr
	python3 -m pip install pycryptodome --user
	python3 -m pip install pyserial --user

.PHONY: bitstream
bitstream:  vivado/vivado.xpr tcl/impl.tcl 
	set -o pipefail && vivado -mode batch -source tcl/impl.tcl -tclargs ${BASE_DIR} ${NUM_CORES}

.PHONY: clean
clean:
	rm -f *.jou *.log *.wdb *.pb *.str *~
	rm -rf xsim.dir .Xil axsim.sh
	rm -rf *_sim.sh
	rm -rf output.txt
	rm -rf *.bz2
	rm -rf *.xpr *.sim *.runs *.hw *.cache *.ip_user_files 
	rm -rf vivado 
