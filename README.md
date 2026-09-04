# RISC-V RV32I Pipelined CPU

A pipelined RV32I core written in Verilog, verified in simulation.

## Status

Fully pipelined CPU implementation completed with flushing, forwarding, and stalling. Verified fully in simulation with all test.

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

**Pipelining** is the idea of doing overlapping different operations (IF, ID, EX, MEM, WB) to increase the throughput(instructions/time). The pipeline was separated into 4 different registers (IF/ID, ID/EX, EX/MEM, MEM/WB) but causes hazards. Hazards occur when the execute operation needs a value that hasn't finished all the stages before it is called. This leads to forwarding, load-use stall, and flushing.

**Forwarding** allows the program to send the final execute or memory stage's value to the current instruction that is calling for its value. Forwarding is used by every operation that has a situation where they call a value that hasn't finished its operations, which is usually when there is no or 1 instruction gap between instructions. 

**Load-use stall** This allows for the program to wait one cycle for the instruction ahead to reach memory. Then the load is in memory, which normal forwarding sends the value.

**Flushing**  A taken branch or jump occurs after finishing EX, but by that time the IF/ID and ID/EX hold instructions from the wrong path. Both are removed.

## Design Decisions

**FENCE** decodes as a NOP. It executes instructions strictly in program order, so no memory reordering exists for FENCE to guard against.

**ECALL and EBREAK** halt simulation instead of trapping. The project scope excludes CSRs and the privileged architecture, so no trap handler exists to jump to. Detection happens in the testbench, not in `cpu_top.v`, keeping the CPU module free of simulation-only constructs. Every other testbench in this project follows the same pattern: `cpu_top.v` describes hardware, the testbench decides when the simulation ends.

**Load/store timing** Block RAM reads synchronously, while my old design had an asynchronous read. I moved the data memory from MEM to EX, which allowed for the BRAM to see the address earlier with the data available at the start of MEM. There are no extra cycles and no change in load-use stall. The stall isn't preventing this instruction because the stall is waiting for the load instruction to be called.

**Register file initialization** X does not exist on hardware, an uninitialized FPGA memory comes up holding whatever the synthesis tool assigned. The register file is therefore initialized to a sentinel value `0xDEADBEEF` via an initial block, which Vivado bakes into the BRAM `INIT` attributes at configuration time rather than costing runtime logic. Zeros were the alternative, rejected because a register reading 0 is indistinguishable from legitimately computed 0, while the sentinel is obviously wrong on sight. 

**imem read timing** `imem` is read combinationally, so it will synthesize as distributed RAM rather than block RAM. Converting it requires the fetch to be registered, which removes the ability to zero `if_id_instr` on a flush and to hold it during a stall, both currently rely on it being a normal register. Deferred until the utilization report shows whether the LUT cost matters.

The initial block sits behind `` `ifdef SYNTHESIS ``, so simulation keeps X while hardware gets the sentinel.

## Known Simulation Artifacts

In `test_lui_auipc`, the ALU output reads X during the EX stage of the instruction. X survives because the sentinel is synthesis only. This is expected, not a bug.

LUI has no rs1 field, bits [19:15], which are a part of the immediate in the format. The decode extracts rs1 unconditionally from every instruction which leads to the bits decoded as x8, which reads a register that no instruction has written. In simulation an unwritten `reg` reads X, so the ALU computes X.

The result is never consumed: `wb_data` muxes LUI to `ex_mem_imm_u` and not `result`. Preventing the read would mean adding decode-dependent logic to the read path to prevent a value that is useless. So the value is just left as is. 

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

FPGA synthesis. This introduces physical limitations to my program that wouldn't be affected in simulation. This means corrections to my program to allow my FPGA to synthesize the program to test on the FPGA. Then I will need to create mapping to correlate different FPGA components to specific features of the CPU. 
