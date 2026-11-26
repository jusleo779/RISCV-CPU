# RISC-V RV32I Pipelined CPU

A pipelined RV32I core written in Verilog, verified in simulation and on an Artix-7 FPGA.

## Status

Fully pipelined RV32I core with forwarding and flushing. Verified in simulation and running on an Arty A7-100T at 50 MHz.

| | |
|---|---|
| ISA | RV32I, 40 instructions |
| Pipeline | 5-stage, full forwarding, no load-use stall |
| Clock | 50 MHz on Arty A7-100T (WNS 2.694 ns) |
| Hardware | Memory-mapped switches and LEDs; `test_compute` validated on board (all 16 switch settings) |
| Tests | 19 directed tests (`make test`) + 39 ACT4 arch-tests, all passing |
| Resources | 1650 (2.6%) LUTs, 388 (<1%) FFs, 556 (3%) LUTRAM |

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
Pipelining is the idea of doing overlapping different operations (IF, ID, EX, MEM, WB) to increase the throughput(instructions/time). The pipeline was separated into 4 different registers (IF/ID, ID/EX, EX/MEM, MEM/WB), but this causes hazards. Hazards occur when the execute operation needs a value that hasn't finished all the stages before it is called. This leads to forwarding and flushing.

### Forwarding
Forwarding allows the program to send the result from a later stage (MEM or WB) back to a later instruction, before the register file has it. Forwarding is used by every operation that has a situation where it calls a value that hasn't finished its operations. There are 3 different cases where forwarding is required. 

- Case 1:  0 separation between instructions, where the EX/MEM stage forwards the `wb_data`
- Case 2:  1 separation between instructions, where the MEM/WB stage forwards the `mem_wb_wb_data`
- Case 3:  2 separation between instructions, where the register file passes the value being written (`rd_data`) to read

With 3 or more instructions between them, the value is already in the register file, so no forwarding is needed.

### Flushing
A taken branch or jump occurs after finishing EX, but by that time the IF/ID and ID/EX hold instructions from the wrong path. Both are removed.

## Design Decisions (Simplified)

| Decision | Choice | Why |
|---|---|---|
| FENCE | NOP | In-order core, nothing to reorder |
| ECALL/EBREAK | Halt in hardware | No CSRs or trap handler in scope |
| Load/Store Timing | Address presented in EX | Synchronous read returns data in MEM, which enabled the stall removal | 
| Load-use Stall | Removed | Forwarding `wb_data` gives load data in time; −1 cycle per load-use |
| Register File Initialization| Sentinel value `0xDEADBEEF` | A stray `0` looks like a real result; the sentinel is obviously wrong |
| Imem Read Timing | kept the LUT RAM usage instead of BRAM  | BRAM needs a registered fetch, which breaks flush-zeroing; LUTRAM use is only ~3% |
| Memory Map | Representation on FPGA using result's bit 31 as an identifier for leds (`0x80000000`) and switches(`0x80000004`)  | bit 31 is never set in a real memory address |
| Clock Rate | targets 50 MHz | The critical path fails when its at 100 MHz |
| `PC + 4` Retiming | moved `PC + 4` from MEM to EX | Shortened 100 MHz critical path by 0.41 ns |
| Reset | 2-flip-flop synchronizer on `clk_50`, starts in reset at power-on | Prevents metastability and flip-flops leaving reset on different cycle when working with an asynchronous button |


 
## Design Decisions (Detailed)

### FENCE
FENCE decodes as a NOP. It executes instructions strictly in program order, so no memory reordering exists for FENCE to guard against.

### ECALL / EBREAK
ECALL and EBREAK halt happens in hardware instead of trapping. The project scope excludes CSRs and the privileged architecture, so no trap handler exists to jump to. Detection happens in `cpu_top.v`, where its output is held as `halted`. It specifically halts `pc` increments and zeroes `if_id_instr`. We only halt these variables, allowing for the draining of the pipelines because `ECALL` requires earlier instructions to complete.

Note: `halted` does not fire on a `flush`

### Load/Store Timing
Block RAM (BRAM) reads synchronously, so the data arrives one cycle after the address. If the address is left in MEM, the data would be available in WB, which requires a two-cycle stall. By presenting the address in EX, the data is available in MEM, the same as the old asynchronous design, which is what made it possible to remove the load-use stall.

### Load-use Stall (removed)
 Previously, an instruction that used a load’s result immediately was stalled for one cycle. The stall was needed because EX/MEM forwarding used `ex_mem_result`, which for a load holds the address (e.g. x1(24) in `test_stall1`), not the data (99). Stalling let the load reach WB, where `mem_wb_wb_data` holds the correct value. Forwarding now uses `wb_data`, which selects `dmem_rdata` for loads, so the stall is no longer needed. Each load-use pair saves one cycle (`test_stall1`: 175 → 165 time units), and timing still passes at 50 MHz (WNS: 2.694 ns).

### Register File Initialization
 X does not exist on hardware; an uninitialized FPGA memory comes up holding whatever the synthesis tool assigned. The register file is therefore initialized to a sentinel value `0xDEADBEEF` via an initial block, which Vivado bakes into the memory’s initial contents at configuration time rather than costing runtime logic. Zeros were the alternative, rejected because a register reading 0 is indistinguishable from legitimately computed 0, while the sentinel is obviously wrong on sight. 

The initial block sits behind `` `ifdef SYNTHESIS ``, so simulation keeps X while hardware gets the sentinel. Vivado defines `SYNTHESIS` automatically, so the guard fires without adding the macro to the synthesis settings.


### Imem Read Timing
`imem` is read combinationally, so it will synthesize as distributed RAM rather than BRAM. Converting it requires the fetch to be registered, which removes the ability to zero `if_id_instr` on a flush that currently relies on it being a normal register. When checking the report, I found that the `imem` uses about 3% of LUTRAM and block RAM has 0 usage. With most of the FPGA's resources unused, converting `imem` to block RAM would free capacity the design has no use for. Worth revisiting if `imem` grows or LUT usage rises.

### Memory Map
`switches` and `led_reg` both required a condition when being loaded or stored onto the FPGA. I decided on `led_reg` to be dependent on bit 31 being 1 and bit 2 being 0 (`0x80000000`) from `result` because bit 31 being 1 will never output a legitimate memory address from `result`. Then we use bit 31 and 2 from `result` as the condition for `switches` (`0x80000004`), where they both have to be 1. This allows for the bit peripherals to be adjacent to each other by an offset of 4. When the `led_reg` condition passes, it will output the low four bits of the stored word to drive LEDs, while the `switches` will use the low four bits of a loaded word. 


### Clock rate
The design targets 50 MHz, not the board's 100 MHz. At 100 MHz, the critical path fails by 2.358 ns, running from `ex_mem_rd` -> `ex_mem_matches_rs1` compare -> forwarding mux (`fwd_a`) -> ALU -> dmem address (`result[11:2]`) -> distributed RAM read -> `dmem_rdata`. About 79% of that delay is routing (signals travelling between parts of the chip) rather than logic.


The limit is structural. Because the dmem address is presented in EX and the load-use stall was removed, forwarding, the ALU, and the memory read all happen in a single cycle. Reaching 100 MHz would mean splitting that chain with a register, which delays load data by a cycle and brings back a load-use stall. That is a trade-off between clock speed and cycles per instruction, so I kept 50 MHz and the one-cycle-faster load-use path. (Before the stall was removed, 100 MHz failed by only 0.364 ns; the stall removal is what turned a near miss into a structural limit.)

A divide-by-two in `cpu_fpga_top` produces the 50 MHz clock, buffered onto a global clock network with a `BUFG`. At 50 MHz: 6616 endpoints, 0 failing, 2.694 ns worst slack.

The divided clock has to be declared in the XDC with `create_generated_clock`. Vivado works out clock frequencies on its own for the FPGA's dedicated clock generators, but a clock built from an ordinary toggling register looks like any other signal to it. Without the declaration, every register in the CPU goes unconstrained: timing analysis reported 1 endpoint instead of the ~6000 timed endpoints.

Timing and utilization are measured with `test_compute.hex` loaded. Because `imem` is a ROM, Vivado optimizes away logic the loaded program never uses, so numbers are only comparable between builds using the same program.

Note: At 50 MHz the tool stops optimizing once timing is met, so slack there reflects placement, not design quality. I compare designs at a constraint they fail, where the tool is pushing hardest.

### `PC + 4` Retiming
JAL and JALR write their return address (`PC + 4`) to `rd`. Originally the adder sat in MEM: `ex_mem_pc` was registered, and `wb_data` computed `ex_mem_pc + 4` when it selected the jump's result. Since EX/MEM forwarding also reads `wb_data`, the 32-bit adder ended up in front of the forwarding mux, and at 100 MHz it became the start of the critical path (`ex_mem_pc` -> PC + 4 adder -> `wb_data` -> forwarding -> ALU -> dmem read).

That forwarding was never actually used. A taken JAL/JALR flushes the two instructions behind it, so when the jump is in MEM, the instruction in EX is always a flushed bubble with nothing to forward to. Writeback still needs `PC + 4`, but nothing needs it in the same cycle.

The fix computes `id_ex_pc + 4` in EX, in parallel with the ALU rather than in series with it, and registers it as `ex_mem_pc_plus4`. Both start from the ID/EX registers on the same clock edge, but the adder's output goes straight into a register and stops, while the other branch continues through forwarding, the ALU, and the dmem read. The adder finishes well before that branch does, so its delay is hidden and no longer adds to the cycle time. `wb_data` now selects a value that is already registered instead of waiting on an adder. `ex_mem_pc` had no other users, so it was replaced, and the flip-flop count is unchanged (386 at the time). All 17 tests still pass, and JAL return addresses in `test_alu` are unchanged.

At 100 MHz, WNS improved from -2.771 ns to -2.358 ns, and failing endpoints dropped from 2003 to 1054. I expected about 2 ns, since the adder alone was about 2.1 ns. The gain was only 0.41 ns because the next-worst path shares the same tail (forwarding -> ALU -> dmem read); removing the adder only cut the front of the path. Fixing the worst path is bounded by the next-worst one. The remaining limit is structural (see Clock rate).


### Reset
`reset` is set during power-on or when the reset button is pressed. On the FPGA, `reset` is activated on a push button press, which works asynchronously to `clk_50` and can cause metastability. Metastability occurs when a flip-flop’s output gets stuck between 0 and 1 when its input changes inside the setup/hold window around its clock edge, causing an unstable signal that randomly outputs 0 or 1. Additionally, the button can cause a skew, where the reset wire reaches about 350 flip-flops at slightly different times, so some flip-flops can leave reset on a different cycle than others. Preventing both requires a synchronizer with two flip-flops clocked by `clk_50`. FF1 captures the possible metastable signal allowing it to settle for a cycle before FF2 samples FF1, which sends the clean stable signal to every flip-flop on the same edge.

Both flip-flops start at 1, so the CPU resets at power-on and resets two cycles later. I excluded the path from the reset pin to FF1 with `set_false_path`: the button has no timing relationship to `clk_50`, so there is nothing to check, and FF1 settles any change that lands near its clock edge. Vivado still times every path after FF1. After the change, the `reset` pin reaches one flip-flop instead of the whole CPU, the TIMING-18 warning is gone, and timed endpoints rose from 6265 to 6615: FF2 now drives the CPU's reset pins, so Vivado can check those paths. On the board, the CPU runs at power-on without a button press.



## Known Simulation Artifacts
In `test_lui_auipc`, the ALU output reads X during the EX stage of the instruction. X survives because the sentinel is synthesis only. This is expected, not a bug.

LUI has no rs1 field, bits [19:15], which are part of the immediate in the format. The decode extracts rs1 unconditionally from every instruction, which leads to the bits being decoded as x8, which reads a register that no instruction has written. In simulation, an unwritten `reg` reads X, so the ALU computes X. This X is harmless: both forwarding and writeback take LUI’s value from `wb_data`, which selects `ex_mem_imm_u` instead of the ALU result.

## Structure

```
arch-test/
  picorv32-rv32imc/         adapted from picorv32 for this core's memory layout and halt
  run_arch.sh               converts each ELF to hex, runs it, prints PASS / FAILED / TIMEOUT
rtl/
  cpu_fpga_top.v            top-level for FPGA and change clock speed to 50 MHz
  cpu_top.v                 top-level datapath and control
  regfile.v                 32x32 register file, x0 hardwired to zero
  alu.v                     10-operation ALU  
  tb_*.v                    one testbench per instruction group
selftest/
  *.s                       assembly test programs
  build.sh                  assemble -> hex -> simulate
Makefile                    make test and make test-<name>  targets
constraints/
  Arty-A7-100-Master.xdc    Digilent, reference, unmodified
  riscv-cpu.xdc             project constraints
```

## Build and Test

```bash
make test-<name>
make test
```

`build.sh` assembles the matching `.s` file with the RISC-V toolchain, converts it to a hex image, compiles the design with Icarus Verilog, and runs the simulation with `vvp`. Each testbench prints `ALL TEST PASSED` or reports the specific register that failed and why.

`make test` will run through each test and will stop at any failing test, exiting with 0 if every test passed and non-zero at the first failure. Each test will have a log saved in `rtl/<name>.log`


## Toolchain

- Icarus Verilog (`iverilog` / `vvp`) for simulation
- GTKWave for waveform inspection
- xPack `riscv-none-elf-gcc` for assembling test programs
- Vivado for synthesis, implementation, and bitstream generation

## Verification Approach

Each instruction group gets its own testbench and test program. Each testbench checks specific expected register values with `if` statements, using `!==` for comparison. Branch tests include cases where signed and unsigned comparison disagree (e.g. BLT vs BLTU on `-1` and `1`) to confirm the sign-extension logic is doing real work, not passing by coincidence. Three load-use tests placed the loaded registers using different operand positions: I-type `rs1`, S-type `rs2`, S-type `rs1`. I/O test (`test_io_loop`) reads the switches and writes the value to the LEDs, in a loop. It tests if the value of the switches changes by writing two different checks. Two load-gap tests, for forwarding situations between 1 and 2 instruction gaps. 

The problem with `vvp` is that it outputs an exit code of 0, even when the test fails. The fix was to add `tee <name>.log && grep -q "ALL TEST PASSED" <name>.log`, where `tee` will save the outputs and output into the log and `grep` checks if the output string is passing. I tested this with `test_stall1`, where I made a failing test without the added `tee <name>.log && grep -q "ALL TEST PASSED" <name>.log`, which revealed an exit code of 0, even though the test failed. But when I added the `tee <name>.log && grep -q "ALL TEST PASSED" <name>.log`, `grep` exits with 1, while `make` exits with 2. After checking this, I restored  `test_stall1` to a passing test and found that with the new added check, it outputted 0. Thus, the extra check prevents hidden errors from occurring.

**Fault injection**. A test that has never failed proves nothing, so each new test is checked by breaking one path in the RTL, confirming the test fails with the predicted value, and restoring it with `git checkout`. This found two gaps: the first one-gap load test exercised only forwarding operand A (fixed by using `add x5, x4, x4`), and `test_compute` v1 combined SLT and SRLI results with OR, which hid an SRA-acting-as-SRL bug (fixed by switching to ADD). In `test_compute` v2, SRA-as-SRL gives LEDs 1011 instead of 1100, and BLT-as-BLTU gives 0011. In `arch-test`, all 39 tests passed, so `sltu` and `sltiu` were purposely broken by changing `a < b` -> `a < (b + 5)`; exactly the 2 predicted tests failed, proving the tests can fail.


## Known Bugs Fixed

- `regfile.v`: x0 write guard existed on the read path but not the write path, so writes to x0 silently succeeded.

- `imm_s`: sign-extension was 20 bits instead of 21.

- ALU control: STORE's opcode wasn't covered in `alu_op_lo`, the same funct3 collision pattern that affected LOAD/SLT.

- `dmem` indexing mixed `result[11:2]` and raw `result` inconsistently between read and write.

- During the EX stage, I forwarded `ex_mem_result`, the previous instruction's ALU output. For LUI, that ALU output (x8 + I-immediate) is not LUI’s real result. This issue didn't affect the loads and jumps because of the flushing protecting JAL/JALR and stalling protecting loads. The fix was to forward `wb_data`, which already had the correct value. I proved that the fix worked by creating `test_lui.s` (`lui x1, 0x12345 -> addi x2, x1, 50`), which originally failed with `x2 = X` and passed with `x2 = 0x12345032`. `wb_data` also selects `dmem_rdata` for loads and `ex_mem_pc_plus4` for JAL/JALR, so forwarding is now correct for every instruction type, not just when the stall or flush happens to prevent the problem.

- `alu.v` and `regfile.v` declared ports without an explicit wire. Under  `` `default_nettype none `` this is invalid, but Icarus compiled it anyway; Vivado rejected it. Added wire to every port declaration.

- `ebreak` and `ecall` could halt the CPU from the ID stage even when that instruction was being flushed. A taken branch or JAL/JALR flushes the next two instructions because they are on the wrong path and should never run. I proved the bug with `test_halt_flush.s`: `blt x1, x2, jump` is taken, and the `ebreak` right after it is on the wrong path. Before the fix, that `ebreak` halted the CPU, so `addi x3, x0, 10` at `jump` never ran and the test failed with `x3 = X`. The fix adds `~flush` to the halt condition (`~flush && (is_ebreak || is_ecall)`), so a flushed `ebreak` or `ecall` can't halt the CPU. After the fix, the test passes with `x3 = 10`.

- The load and store operations failed on all operations besides `lw` and `sw`, because load/store operations would output/copy the full word instead of specific bytes of the word. I proved the bug through `test_subword.s`, which had a background value `0x11223344` that helps differentiate between replacing specific bytes v.s. changing more bytes than told to. Before the fix, `sh` and `sb` would take the whole word to store and change parts of the output (ex. `0x11223344 -> 0x000000AB`, expected `0x1122AB44`  (`sb`), `0x11223344 -> 0x0000BEEF`, expected `0xBEEF3344` (`sh`)). This test also covered load operations, `lh`, `lb`, `lhu`, `lbu`, which failed at filling with the signed/unsigned bits and instead outputted the word again (ex. `0x80017F9C -> 0x80017F9C`, expected `0xFFFFFF9C` for `lb x12, 0(x6)` or `0x80017F9C -> 0x80017F9C`, expected `0x0000009C` for `lbu x13, 0(x6)`). The fix added a dependency on `id_ex_funct3[2:0]`, which decides load/store width and sign, while `result[1:0]` decides the byte lanes. The other fix was outputting the correct signed extensions for `lh`/`lb` or zero extensions for `lhu`/`lbu` to fill the upper bits of the output. After the fix, all 19 tests passed with the correct outputs.


### Board test: `test_compute`

The deployed program reads the 4 switches, does a signed compute, and writes the result to the 4 LEDs. Every switch setting gives a different LED pattern, so a wrong ALU or branch result shows up as a visible mismatch.

| d = s − 8 | Switches | LEDs | | d = s − 8 | Switches | LEDs |
|:---:|:---:|:---:|---|:---:|:---:|:---:|
| −8 | 0000 | 1111 | | 0 | 1000 | 0000 |
| −7 | 0001 | 1110 | | 1 | 1001 | 0001 |
| −6 | 0010 | 1101 | | 2 | 1010 | 0010 |
| −5 | 0011 | 1100 | | 3 | 1011 | 0011 |
| −4 | 0100 | 1011 | | 4 | 1100 | 0100 |
| −3 | 0101 | 1010 | | 5 | 1101 | 0101 |
| −2 | 0110 | 1001 | | 6 | 1110 | 0110 |
| −1 | 0111 | 1000 | | 7 | 1111 | 0111 |

- **sw 0xxx:** LEDs = 15 − s (every bit flipped). This path takes the `blt` branch and uses `srai`.
- **sw 1xxx:** LEDs = s − 8 (bit 3 cleared). This path doesn't take the branch.

**What a failure looks like:**
| Symptom | Likely cause |
|---|---|
| LEDs = switches on 0xxx | `blt` acting like `bltu` (branch never taken) |
| sw `0011` → LEDs `1011` | `srai` acting like `srli` |
| LEDs stuck at `0000` | CPU not running / reset not pressed |

Note: sw `1000` correctly shows `0000`, which looks the same as a stuck CPU. Check another 1xxx setting to tell them apart.

Chart worked out by hand from the RV32I spec, not from simulation output. Verified on the Arty A7-100T at 50 MHz: Nov 22, 2026 all 16 settings.


### Arch-Test

All 39 RV32I tests pass (Nov 26, 2026, commit `669a905`)
Not covered: ecall, ebreak, misaligned access.

The CPU passes the arch-test suite (ACTs, Architectural Certification Tests) from RISC-V International, run with the ACT4 framework and ported to this core in `arch-test/`.

ACT4 checks itself by first doing the instruction under test, then a load of the right answer. The right answer was computed by Sail, the reference model, when the test was built, and stored in the program's data before it ran. We then compare if both are equal to each other using `beq`. If the check passes it skips `jal` and two `.word`s and continues to the next check. If it fails it will jump to the failure code, which reads the two `.word`s: the address of the check it failed on and a pointer to a description of the failed test.

We know if the test passed for real by purposefully breaking the CPU to check for failure. When a test is unable to fail, it can cause a false pass. For example, breaking `sltu` and `sltiu` by changing the comparison to `a < (b + 5)` caused exactly the 2 predicted failures (`I-sltu-00`, `I-sltiu-00`); the other 37 still passed. The second check (done for `I-add-00`) we need to do is comparing the amount of checks in the program compared to my run's amount of skipped checks. 392 checks in the program, 392 skipped in the run. When we see the skips and checks are the same we know every check ran and passed. For `I-add-00`, we also compared to our predictions by calculating and comparing the cycle count of the answer. When our predictions were different, we had to check the program for skipped test cases.

```bash
# 1. Build the 39 ELFs (needs riscv-arch-test cloned to ~/projects, plus Sail and the RISC-V toolchain)
cd ~/projects/riscv-arch-test
make CONFIG_FILES=~/projects/riscv-cpu/arch-test/picorv32-rv32imc/test_config.yaml EXTENSIONS=I DEBUG=True WORKDIR=~/projects/riscv-cpu/arch-test/work

# 2. Run all 39 (from the riscv-cpu repo root)
cd ~/projects/riscv-cpu
chmod +x arch-test/run_arch.sh   # once
./arch-test/run_arch.sh
```

## Scope

RV32I base integer instruction set, 40 instructions (with EBREAK/ECALL-as-halted and FENCE-as-NOP). No CSR support, no privileged architecture, no interrupt handling. Pipelined with forwarding and flushing. Misaligned loads/stores are not supported (no trap).

The loads and stores are not trapped when working with addresses that are not naturally aligned. For example, an offset of 1 for lw will give the word from an offset of 0 instead of taking 3 bytes from the current word and 1 byte from the next word. This means that the lower address bits are ignored and rounded down to the nearest aligned address

## Future Project Extension

Hardware validation covers `test_io_loop` (switches → LEDs) and `test_compute`, where shifts, a signed compare, and a signed branch determine the LED output; all 16 switch settings were checked against a hand-derived chart.

Still open:
- RTL-to-GDSII flow (Cadence/Synopsys) on the frozen RTL
- `imem` conversion to block RAM, deferred while resource usage stays low

