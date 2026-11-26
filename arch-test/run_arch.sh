#!/bin/bash
# Run every ACT4 RV32I test on the CPU; print PASS / FAILED / TIMEOUT per test.
# Usage (from the repo root):  ./arch-test/run_arch.sh
# Exits 1 if any test does not pass (fails loudly, like make test).

#Command: chmod +x arch-test/run_arch.sh (setup)
#         ./arch-test/run_arch.sh (run)


# Folder directories
ELF_DIR=arch-test/work/rv32I/elfs/rv32i/I
HEX_DIR=arch-test/hex
LOG_DIR=arch-test/logs
mkdir -p "$HEX_DIR" "$LOG_DIR"

pass=0
fail=0
timeout=0

for f in "$ELF_DIR"/*.elf; do
    name=$(basename "$f" .elf) #  (basename) remove the folder path and the .elf at the end of the file name

# 1. ELF -> flat binary -> one 32-bit word per line for $readmemh

    riscv-none-elf-objcopy -O binary "$f" "$HEX_DIR/$name.bin"  # create a bin from the name above
    # create a hex file from the bin: 4 bytes per line (one 32-bit word), -e for little-endian, and cut keeps only the word column
    xxd -e -c 4 "$HEX_DIR/$name.bin" | cut -d' ' -f2 > "$HEX_DIR/$name.hex" 

########################################################################################################################################

# 2. Compile tb_arch with this test's hex file name in the HEX macro

    # if the compile fails (syntax error, missing .v file), report it and skip this test so the previous test's arch.vvp isn't run by mistake
    if ! (cd rtl && iverilog "-DHEX=\"$name.hex\"" -o arch.vvp tb_arch.v cpu_top.v alu.v regfile.v); then
        echo "COMPILE ERROR  $name"
        fail=$((fail + 1))
        continue
    fi

###########################################################################################################################################

# 3. Run; keep stdout and stderr in one log per test

    (cd rtl && vvp arch.vvp) > "$LOG_DIR/$name.log" 2>&1

##########################################################################################################################################

# 4. Classify. TIMEOUT first: the timeout branch also prints FAILED

    if grep -q "TIMEOUT" "$LOG_DIR/$name.log"; then # grabs from the files and checks for "TIMEOUT"
        echo "TIMEOUT        $name"
        timeout=$((timeout + 1))
    elif grep -q "ALL TEST PASSED" "$LOG_DIR/$name.log"; then
        # if passes print out pass and the name of the test with the log of halted at # cycles from the specific log file
        echo "PASS           $name  ($(grep -o 'Halted at [0-9]* cycles' "$LOG_DIR/$name.log"))" 
        pass=$((pass + 1))
    else
        echo "FAILED         $name  ($(grep -m1 'FAILED' "$LOG_DIR/$name.log"))"
        fail=$((fail + 1))
    fi
done

###########################################################################################################################################

total=$((pass + fail + timeout)) # count the total 
echo "----"
# output fraction of how many passed over total, failed, timed out
echo "$pass / $total passed, $fail failed, $timeout timed out" 

# exit code: 0 only if every test passed, so the script fails loudly like make test
[ "$pass" -eq "$total" ]
