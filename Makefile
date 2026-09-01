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

test-stall1:
	bash selftest/build.sh test_stall1
	iverilog -o rtl/stall1.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall1.v
	cd rtl && vvp stall1.vvp

test-stall2:
	bash selftest/build.sh test_stall2
	iverilog -o rtl/stall2.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall2.v
	cd rtl && vvp stall2.vvp

test-stall3:
	bash selftest/build.sh test_stall3
	iverilog -o rtl/stall3.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall3.v
	cd rtl && vvp stall3.vvp

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

	bash selftest/build.sh test_lui_auipc
	iverilog -o rtl/lui_auipc.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_lui_auipc.v
	cd rtl && vvp lui_auipc.vvp

	bash selftest/build.sh test_fence
	iverilog -o rtl/fence.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_fence.v
	cd rtl && vvp fence.vvp

	bash selftest/build.sh test_ecall
	iverilog -o rtl/ecall.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ecall.v
	cd rtl && vvp ecall.vvp

	bash selftest/build.sh test_ebreak
	iverilog -o rtl/ebreak.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_ebreak.v
	cd rtl && vvp ebreak.vvp

	bash selftest/build.sh test_stall1
	iverilog -o rtl/stall1.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall1.v
	cd rtl && vvp stall1.vvp
	
	bash selftest/build.sh test_stall2
	iverilog -o rtl/stall2.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall2.v
	cd rtl && vvp stall2.vvp

	bash selftest/build.sh test_stall3
	iverilog -o rtl/stall3.vvp rtl/cpu_top.v rtl/regfile.v rtl/alu.v rtl/tb_stall3.v
	cd rtl && vvp stall3.vvp
	
clean:
	rm -f rtl/*.vvp rtl/*.vcd selftest/*.o selftest/*.elf selftest/*.bin
