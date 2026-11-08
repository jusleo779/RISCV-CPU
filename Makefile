test-alu:
	bash selftest/build.sh test_alu
	iverilog -o rtl/alu.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_alu.v
	cd rtl && vvp alu.vvp | tee alu.log && grep -q "ALL TEST PASSED" alu.log

test-branch:
	bash selftest/build.sh test_branch
	iverilog -o rtl/branch.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_branch.v
	cd rtl && vvp branch.vvp | tee branch.log && grep -q "ALL TEST PASSED" branch.log

test-load_store:
	bash selftest/build.sh test_load_store
	iverilog -o rtl/load_store.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_load_store.v
	cd rtl && vvp load_store.vvp | tee load_store.log && grep -q "ALL TEST PASSED" load_store.log

test-lui_auipc:
	bash selftest/build.sh test_lui_auipc
	iverilog -o rtl/lui_auipc.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_lui_auipc.v
	cd rtl && vvp lui_auipc.vvp | tee lui_auipc.log && grep -q "ALL TEST PASSED" lui_auipc.log

test-lui:
	bash selftest/build.sh test_lui
	iverilog -o rtl/lui.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_lui.v
	cd rtl && vvp lui.vvp | tee lui.log && grep -q "ALL TEST PASSED" lui.log

test-fence:
	bash selftest/build.sh test_fence
	iverilog -o rtl/fence.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_fence.v
	cd rtl && vvp fence.vvp | tee fence.log && grep -q "ALL TEST PASSED" fence.log

test-ecall:
	bash selftest/build.sh test_ecall
	iverilog -o rtl/ecall.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ecall.v
	cd rtl && vvp ecall.vvp | tee ecall.log && grep -q "ALL TEST PASSED" ecall.log

test-ebreak:
	bash selftest/build.sh test_ebreak
	iverilog -o rtl/ebreak.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ebreak.v
	cd rtl && vvp ebreak.vvp | tee ebreak.log && grep -q "ALL TEST PASSED" ebreak.log

test-stall1:
	bash selftest/build.sh test_stall1
	iverilog -o rtl/stall1.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall1.v
	cd rtl && vvp stall1.vvp | tee stall1.log && grep -q "ALL TEST PASSED" stall1.log

test-load_gap1:
	bash selftest/build.sh test_load_gap1
	iverilog -o rtl/load_gap1.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_load_gap1.v
	cd rtl && vvp load_gap1.vvp | tee load_gap1.log && grep -q "ALL TEST PASSED" load_gap1.log

test-stall2:
	bash selftest/build.sh test_stall2
	iverilog -o rtl/stall2.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall2.v
	cd rtl && vvp stall2.vvp | tee stall2.log && grep -q "ALL TEST PASSED" stall2.log

test-load_gap2:
	bash selftest/build.sh test_load_gap2
	iverilog -o rtl/load_gap2.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_load_gap2.v
	cd rtl && vvp load_gap2.vvp | tee load_gap2.log && grep -q "ALL TEST PASSED" load_gap2.log

test-stall3:
	bash selftest/build.sh test_stall3
	iverilog -o rtl/stall3.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall3.v
	cd rtl && vvp stall3.vvp | tee stall3.log && grep -q "ALL TEST PASSED" stall3.log

test-led:
	bash selftest/build.sh test_led
	iverilog -o rtl/led.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_led.v
	cd rtl && vvp led.vvp | tee led.log && grep -q "ALL TEST PASSED" led.log

test-switch:
	bash selftest/build.sh test_switch
	iverilog -o rtl/switch.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_switch.v
	cd rtl && vvp switch.vvp | tee switch.log && grep -q "ALL TEST PASSED" switch.log

test-io_loop:
	bash selftest/build.sh test_io_loop
	iverilog -o rtl/io_loop.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_io_loop.v
	cd rtl && vvp io_loop.vvp | tee io_loop.log && grep -q "ALL TEST PASSED" io_loop.log

test-compute:
	bash selftest/build.sh test_compute
	iverilog -o rtl/compute.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_compute.v
	cd rtl && vvp compute.vvp | tee compute.log && grep -q "ALL TEST PASSED" compute.log



test:	test-alu	test-branch	test-load_store	test-lui_auipc	test-lui	test-fence	test-ecall	test-ebreak	\
		test-stall1	test-load_gap1	test-stall2	test-load_gap2	test-stall3	test-led	test-switch	test-io_loop \
		test-compute
	
	
clean:
	rm -f rtl/*.vvp rtl/*.vcd selftest/*.o selftest/*.elf selftest/*.bin
