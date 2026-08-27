test-alu:
	bash selftest/build.sh test_alu
	iverilog -o rtl/alu.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_alu.v
	cd rtl && vvp alu.vvp

test-branch:
	bash selftest/build.sh test_branch
	iverilog -o rtl/branch.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_branch.v
	cd rtl && vvp branch.vvp

test-load_store:
	bash selftest/build.sh test_load_store
	iverilog -o rtl/load_store.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_load_store.v
	cd rtl && vvp load_store.vvp

test-lui_auipc:
	bash selftest/build.sh test_lui_auipc
	iverilog -o rtl/lui_auipc.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_lui_auipc.v
	cd rtl && vvp lui_auipc.vvp

test-fence:
	bash selftest/build.sh test_fence
	iverilog -o rtl/fence.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_fence.v
	cd rtl && vvp fence.vvp

test-ecall:
	bash selftest/build.sh test_ecall
	iverilog -o rtl/ecall.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ecall.v
	cd rtl && vvp ecall.vvp

test-ebreak:
	bash selftest/build.sh test_ebreak
	iverilog -o rtl/ebreak.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ebreak.v
	cd rtl && vvp ebreak.vvp

test:
	bash selftest/build.sh test_branch
	iverilog -o rtl/branch.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_branch.v
	cd rtl && vvp branch.vvp

	bash selftest/build.sh test_alu
	iverilog -o rtl/alu.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_alu.v
	cd rtl && vvp alu.vvp

	bash selftest/build.sh test_load_store
	iverilog -o rtl/load_store.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_load_store.v
	cd rtl && vvp load_store.vvp
	
clean:
	rm -f rtl/*.vvp rtl/*.vcd selftest/*.o selftest/*.elf selftest/*.bin
