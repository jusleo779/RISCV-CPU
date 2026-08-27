# RISC-V RV32I Single-Cycle CPU

A single-cycle RV32I core written in Verilog, verified in simulation.

## Status

Single-cycle implementation complete. All 38 in-scope instructions decode and execute correctly, verified against hand-computed expected values.

## Instructions Implemented

**R-type:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

**I-type:** ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, JALR, LB, LH, LW, LBU, LHU

**S-type:** SB, SH, SW

**B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU

**U-type:** LUI, AUIPC

**J-type:** JAL

**System:** FENCE, ECALL, EBREAK

## Design Decisions

**FENCE** decodes as a NOP. A single-cycle core executes instructions strictly in program order, so no memory reordering exists for FENCE to guard against.

**ECALL and EBREAK** halt simulation instead of trapping. The project scope excludes CSRs and the privileged architecture, so no trap handler exists to jump to. Detection happens in the testbench, not in `cpu_top.v`, keeping the CPU module free of simulation-only constructs. Every other testbench in this project follows the same pattern: `cpu_top.v` describes hardware, the testbench decides when the simulation ends.

**Load/store timing.** The single-cycle design assumes asynchronous-read memory. FPGA block RAM reads synchronously, so this design targets simulation. FPGA deployment is deferred to the pipelined version.

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
- Vivado, for the eventual FPGA target on the pipelined version

## Verification Approach

Each instruction group gets its own testbench and test program. Assertions check specific expected register values, not just "no X-state," using `!==` for comparison. Branch tests include cases where signed and unsigned comparison disagree (e.g. BLT vs BLTU on `-1` and `1`) to confirm the sign-extension logic is doing real work, not passing by coincidence.

## Known Bugs Fixed

- `regfile.v`: x0 write guard existed on the read path but not the write path, so writes to x0 silently succeeded.
- `imm_s`: sign-extension was 20 bits instead of 21.
- ALU control: STORE's opcode wasn't covered in `alu_op_lo`, the same funct3 collision pattern that affected LOAD/SLT.
- `dmem` indexing mixed `result[11:2]` and raw `result` inconsistently between read and write.

## Scope

RV32I base integer instruction set, 38 instructions per the original scoping document (40 unique instructions, minus the SYSTEM collapse and FENCE-as-NOP simplification). No CSR support, no privileged architecture, no interrupt handling. Single-cycle only; pipelining is the next phase.

## Next Steps

Pipelining. This introduces structural, data, and control hazards that don't exist in the single-cycle design by construction. The current testbenches assume single-cycle timing and will need rework to catch pipeline-specific bugs (e.g. forwarding failures, stalls) rather than just checking final register state.
