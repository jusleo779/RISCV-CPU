#!/bin/bash
set -e
cd "$(dirname "$0")"
PREFIX=riscv-none-elf-

${PREFIX}as -march=rv32i -mabi=ilp32 -o $1.o $1.s
${PREFIX}ld -Ttext=0x0 $1.o -o $1.elf
${PREFIX}objcopy -O binary $1.elf $1.bin
xxd -e -c 4 $1.bin | cut -d' ' -f2 > $1.hex

echo "--- disassembly ---"
${PREFIX}objdump -d $1.elf