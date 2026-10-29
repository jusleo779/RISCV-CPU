# RISC-V RV32I Pipelined CPU

A pipelined RV32I core written in Verilog, verified in simulation.

## Status

Fully pipelined RV32I core with forwarding and flushing. Verified in simulation and running on an Arty A7-100T at 50 MHz.

| | |
|---|---|
| ISA | RV32I, 40 instructions |
| Pipeline | 5-stage, full forwarding, no load-use stall |
| Clock | 50 MHz on Arty A7-100T (WNS 4.482 ns) |
| Hardware | Memory-mapped switches and LEDs; `test_io_loop` validated on board |
| Tests | 14 simulation tests (`make test`) |
| Resources | 1329 (2%) LUTs, 329 (1%) FFs, 556 (3%) LUTRAM |

## Instructions Implemented

**R-type:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

**I-type:** ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, JALR, LB, LH, LW, LBU, LHU

**S-type:** SB, SH, SW

**B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU

**U-type:** LUI, AUIPC

**J-type:** JAL

**System:** FENCE (NOP), ECALL/EBREAK(halted)


## Architecture

**IF (Instruction Fetch)** --- Reads the instruction from memory of pc

**ID (Instruction Decode)** --- Interprets the instructions from memory into the correct formatting, reads register file, and builds the immediate values

**EX (Execute)** --- Computes the arithmetic operations, instructions, and address calculation for loads/ stores / JAL/ JALR/ branches.

**MEM (Memory)** --- loads, reads, stores, and writes to data memory. If operation isn't needed then it becomes idle until moves to next stage

**WB (Write Back)** --- results of the computation and operations is written into rd in the register file


## Pipeline

### Pipelining
Pipelining is the idea of doing overlapping different operations (IF, ID, EX, MEM, WB) to increase the throughput(instructions/time). The pipeline was separated into 4 different registers (IF/ID, ID/EX, EX/MEM, MEM/WB) but causes hazards. Hazards occur when the execute operation needs a value that hasn't finished all the stages before it is called. This leads to forwarding and flushing.

### Forwarding
Forwarding allows the program to send the result from a later stage (MEM or WB) back to a later instruction, before the register file has it. Forwarding is used by every operation that has a situation where they call a value that hasn't finished its operations. There are 3 different cases, where forwarding is required. 

- Case 1:  0 separation between instructions, where EX/MEM stage forwards the `wb_data`
- Case 2:  1 separation between instructions, where MEM/WB stage forwards the `mem_wb_wb_data`
- Case 3:  2 separation between instructions, where the register file passes the value being written (`rd_data`) to read

With 3 or more instructions between them, the value is already in the register file, so no forwarding is needed.

### Flushing
A taken branch or jump occurs after finishing EX, but by that time the IF/ID and ID/EX hold instructions from the wrong path. Both are removed.

## Design Decisions

| Decision | Choice | Why |
|---|---|---|
| FENCE | NOP | In-order core, nothing to reorder |
| ECALL/EBREAK | Halt in hardware | No CSRs or trap handler in scope |
| Load/Store Timing | Address presented in EX | Synchronous read returns data in MEM, which enabled the stall removal | 
| Load-use Stall | Removed | Forwarding `wb_data` gives load data in time; −1 cycle per load-use |
| Register File Initialization| Sentinel value `0xDEADBEEF` | A stray `0` looks like a real result; the sentinel is obviously wrong |
| Imem Read Timing | kept the LUT RAM usage instead of BRAM  | BRAM needs a registered fetch, which breaks flush-zeroing; LUTRAM use is only ~3% |
| Memory Map | Representation on FPGA using result's bit 31 as an identifier for leds (`0x80000000`) and switches(`0x80000004`)  | bit 31 is never set in a real memory address |
| Clock Rate | targets 50 MHz | The critical path fails when its at 100 MHz with the stall (retest pending) |


### FENCE
FENCE decodes as a NOP. It executes instructions strictly in program order, so no memory reordering exists for FENCE to guard against.

### ECALL / EBREAK
ECALL and EBREAK halt happens in hardware instead of trapping. The project scope excludes CSRs and the privileged architecture, so no trap handler exists to jump to. Detection happens in `cpu_top.v`, where its output is held as `halted`. It specifically halts `pc` increments and zeroes `if_id_instr`. We only halt these variables allowing for the draining of the pipelines because `ECALL` requires earlier instructions to complete.

### Load/Store Timing
Block RAM (BRAM) reads synchronously, so the data arrives one cycle after the address. If the address is left in MEM, the data would be available in WB, which requires a two-cycle stall. By presenting the address in EX, the data is available in MEM, the same as the old asynchronous design, which is what made it possible to remove the load-use stall.

### Load-use Stall (removed)
 Previously, an instruction that used a load’s result immediately was stalled for one cycle. The stall was needed because EX/MEM forwarding used `ex_mem_result`, which for a load holds the address (e.g. x1(24) in `test_stall1`), not the data (99). Stalling let the load reach WB, where `mem_wb_wb_data` held the correct value. Forwarding now uses `wb_data`, which selects `dmem_rdata` for loads, so the stall is no longer needed. Each load-use pair saves one cycle (`test_stall1`: 175 → 165 time units), and timing still passes at 50 MHz (WNS: 4.482 ns).

### Register File Initialization
 X does not exist on hardware; an uninitialized FPGA memory comes up holding whatever the synthesis tool assigned. The register file is therefore initialized to a sentinel value `0xDEADBEEF` via an initial block, which Vivado bakes into the memory’s initial contents at configuration time rather than costing runtime logic. Zeros were the alternative, rejected because a register reading 0 is indistinguishable from legitimately computed 0, while the sentinel is obviously wrong on sight. 

The initial block sits behind `` `ifdef SYNTHESIS ``, so simulation keeps X while hardware gets the sentinel. Vivado defines `SYNTHESIS` automatically, so the guard fires without adding the macro to the synthesis settings.


### Imem Read Timing
`imem` is read combinationally, so it will synthesize as distributed RAM rather than BRAM. Converting it requires the fetch to be registered, which removes the ability to zero `if_id_instr` on a flush that currently relies on it being a normal register. When checking the report, I found that the `imem` uses about 3% of LUTRAM and block RAM has 0 usage. With most of the FPGA's resources unused, converting `imem` to block RAM would free capacity the design has no use for. Worth revisiting if `imem` grows or LUT usage rises.

### Memory Map
`switches` and `led_reg` both required a condition when being loaded or stored onto the FPGA. I decided on `led_reg` to be dependent on bit 31 being 1 and bit 2 being 0 (`0x80000000`) from `result` because bit 31 being 1 will never output a legitimate memory address from `result`. Then we use bit 31 and 2 from `result` as the condition for `switches` (`0x80000004`) where they both have to be 1. This allows for the bit peripheral to be adjacent to each other by an offset of 4. When the `led_reg` condition passes it will output the low four bits of the stored word to drive leds, while the `switches` will use the low four bits of a loaded word. 

### Clock rate
The design targets 50 MHz, not the board's 100 MHz. At 100 MHz the critical path fails by 0.364 ns (measured before the load-use stall was removed), running from `ex_mem_reg_write` through the forwarding mux and ALU to the `dmem` address, then through distributed RAM to `dmem_rdata`. Most of that time is the signal travelling between parts of the chip rather than the logic computing anything, so simplifying the logic would not fix it. A divide-by-two in `cpu_fpga_top` produces the 50 MHz clock, buffered onto a global clock network with a `BUFG`. At 50 MHz: 5964 endpoints, 0 failing, 4.482 ns worst slack.

The divided clock has to be declared in the XDC with `create_generated_clock`. Vivado works out clock frequencies on its own for the FPGA's dedicated clock generators, but a clock built from an ordinary toggling register looks like any other signal to it. Without the declaration, every register in the CPU goes unconstrained: timing analysis reported 1 endpoint instead of the ~6000 timed endpoints.




## Known Simulation Artifacts

In `test_lui_auipc`, the ALU output reads X during the EX stage of the instruction. X survives because the sentinel is synthesis only. This is expected, not a bug.

LUI has no rs1 field, bits [19:15], which are a part of the immediate in the format. The decode extracts rs1 unconditionally from every instruction which leads to the bits decoded as x8, which reads a register that no instruction has written. In simulation an unwritten `reg` reads X, so the ALU computes X. This X is harmless: both forwarding and writeback take LUI’s value from `wb_data`, which selects `ex_mem_imm_u` instead of the ALU result.

## Structure

```
rtl/
  cpu_fpga_top.v            top-level for FPGA and change clock speed to 50 MHz
  cpu_top.v                 top-level datapath and control
  regfile.v                 32x32 register file, x0 hardwired to zero
  alu.v                     10-operation ALU  
  tb_*.v                    one testbench per instruction group
selftest/
  *.s                       assembly test programs
  build.sh                  assemble -> hex -> simulate
Makefile                    make test-<name> targets
constraints/
  Arty-A7-100-Master.xdc    Digilent, reference, unmodified
  riscv-cpu.xdc             project constraints
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
- Vivado for synthesis, implementation, and bitstream generation

## Verification Approach

Each instruction group gets its own testbench and test program. Assertions check specific expected register values, not just "no X-state," using `!==` for comparison. Branch tests include cases where signed and unsigned comparison disagree (e.g. BLT vs BLTU on `-1` and `1`) to confirm the sign-extension logic is doing real work, not passing by coincidence. Three load-use tests placed the loaded registers using different operand positions: I-type `rs1`, S-type `rs2`, S-type `rs1`. I/O test (`test_io_loop`) reads the switches and writes the value to the leds, in a loop. It tests if the value of the switches change by writing two different assertions. 

## Known Bugs Fixed

- `regfile.v`: x0 write guard existed on the read path but not the write path, so writes to x0 silently succeeded.
- `imm_s`: sign-extension was 20 bits instead of 21.
- ALU control: STORE's opcode wasn't covered in `alu_op_lo`, the same funct3 collision pattern that affected LOAD/SLT.
- `dmem` indexing mixed `result[11:2]` and raw `result` inconsistently between read and write.
- During EX stage, I forwarded `ex_mem_result`, the previous instruction's ALU output. For LUI, that ALU output (x8 + I-immediate) is not LUI’s real result. This issue didn't affect the loads and jumps because of the flushing protecting JAL/JALR and stalling protecting load. The fix was to forward `wb_data`, which already had the correct value. I proved that the fix worked by creating `test_lui.s` (`lui x1, 0x12345 -> addi x2, x1, 50`), which originally failed with `x2 = X` and passed with `x2 = 0x12345032`. `wb_data` also selects `dmem_rdata` for loads and `ex_mem_pc + 4` for JAL/JALR, so forwarding is now correct for every instruction type, not just when the stall or flush happens to prevent the problem.
- `alu.v` and `regfile.v` declared ports without an explicit wire. Under  `` `default_nettype none `` this is invalid, but Icarus compiled it anyway; Vivado rejected it. Added wire to every port declaration.

## Scope

RV32I base integer instruction set, 40 instructions (with EBREAK/ECALL-as-halted and FENCE-as-NOP). No CSR support, no privileged architecture, no interrupt handling. Pipelined with forwarding and flushing.

## Future Project Extension

Hardware validation so far covers a single program that reads the switches and writes their value to the LEDs. Branches, jumps, and arithmetic are verified in simulation but have not been exercised on the board. The next useful step is a program whose output depends on computation rather than data movement.

Also open:
- `imem` conversion to block RAM, deferred while FPGA resource usage stays low
