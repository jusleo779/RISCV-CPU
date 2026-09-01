# RISC-V RV32I Pipelined CPU

A pipelined RV32I core written in Verilog, verified in simulation.

## Status

Fully pipelined CPU implementation completed with flushing, forwarding, and stalling. Verified fully in simulation with all test passing with new architecture. 

## Instructions Implemented

**R-type:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

**I-type:** ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, JALR, LB, LH, LW, LBU, LHU

**S-type:** SB, SH, SW

**B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU

**U-type:** LUI, AUIPC

**J-type:** JAL

**System:** FENCE, ECALL, EBREAK


## Architecture

**IF (Instruction Fetch)** --- Reads the instruction from memory of pc

**ID (Instruction Decode)** --- Interprets the instructions from memory into the correct formatting, reads register file, and builds the immediate values

**EX (Execute)** --- Computes the arithmetic operations, instructions, and address calculation for loads/ stores / JAL/ JALR/ branches.

**MEM (Memory)** --- loads, reads, stores, and writes to data memory. If operation isn't needed then it becomes idle until moves to next stage

**WB (Write Back)** --- results of the computation and operations is written into rd in the register file


## Pipeline

**Pipelining** is the idea of doing overlapping different operations (IF, ID, EX, MEM, WB) to increase the throughput(instructions/time). The pipeline was seperated into 4 different registers but causes hazards. Hazards occur when the execute operation needs a value from the an instruction above that hasn't finished all the stages before it's called. This leads to forwarding, load-use stall, and flushing.

**Forwarding** allows the program to send the final execute or memory stage's value to the current instruction that is calling for it's value. Forwarding is used by every operation that has a situation where they call a value that hasn't finished it's operations, which is usually when there is no or 1 instruction gap between instructions. 

**Load-use stall** This allows for the program to wait for the instruction ahead to reach the memory/write back stage to forward the value to the instruction that is calling it.

**Flushing** is used when we are using JAL, JALR, or branch which skips over the next instruction but due to the pipelining it will save the instruction that shouldn't be saved.


## Design Decisions

**FENCE** decodes as a NOP. It executes instructions strictly in program order, so no memory reordering exists for FENCE to guard against.

**ECALL and EBREAK** halt simulation instead of trapping. The project scope excludes CSRs and the privileged architecture, so no trap handler exists to jump to. Detection happens in the testbench, not in `cpu_top.v`, keeping the CPU module free of simulation-only constructs. Every other testbench in this project follows the same pattern: `cpu_top.v` describes hardware, the testbench decides when the simulation ends.

**Load/store timing.** The design assumes asynchronous-read memory. FPGA block RAM reads synchronously, so this design targets simulation. FPGA deployment deferred to future work. 

## Structure

```
rtl/
  cpu_top.v       top-level datapath and control
  regfile.v       32x32 register file, x0 hardwired to zero
  alu.v           10-operation ALU
  tb_*.v          one testbench per instruction group
selftest/
  *.s             assembly test programs
  build.sh        assemble -> hex -> simulate
Makefile          make test-<name> targets
```

## Build and Test

```bash
make test-<name>
```

`build.sh` assembles the matching `.s` file with the RISC-V toolchain, converts to a hex image, compiles the design with Icarus Verilog, and runs the simulation with `vvp`. Each testbench prints `ALL TEST PASSED` or reports the specific register that failed and why.

## Toolchain

- Icarus Verilog (`iverilog` / `vvp`) for simulation
- GTKWave for waveform inspection
- xPack `riscv-none-elf-gcc` for assembling test programs
- Vivado, for the FPGA testing bring-up on chip

## Verification Approach

Each instruction group gets its own testbench and test program. Assertions check specific expected register values, not just "no X-state," using `!==` for comparison. Branch tests include cases where signed and unsigned comparison disagree (e.g. BLT vs BLTU on `-1` and `1`) to confirm the sign-extension logic is doing real work, not passing by coincidence. Three stall tests placed the loaded registers using different operand positions: I-type `rs1`, S-type `rs2`, S-type `rs1`.

## Known Bugs Fixed

- `regfile.v`: x0 write guard existed on the read path but not the write path, so writes to x0 silently succeeded.
- `imm_s`: sign-extension was 20 bits instead of 21.
- ALU control: STORE's opcode wasn't covered in `alu_op_lo`, the same funct3 collision pattern that affected LOAD/SLT.
- `dmem` indexing mixed `result[11:2]` and raw `result` inconsistently between read and write.
- The forwarding mux selected `ex_mem_result` without checking for a load so the computed address got forwarded instead of the loaded word

## Scope

RV32I base integer instruction set, 38 instructions per the original scoping document (40 unique instructions, minus the SYSTEM collapse and FENCE-as-NOP simplification). No CSR support, no privileged architecture, no interrupt handling. Pipelined with stalling, forwarding, and flushing.

## Next Steps

FPGA synthesis. This introduces physical limitations to my program that wouldn't be affected in simulation. This means multiple checks and corrections to my program to allow my FPGA to synthesize the program to test on the FPGA. Then I will need to create mapping to correlate different FPGA components to specific features of the CPU. 
