#!/bin/bash
set -e
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o $1.o $1.s
riscv64-unknown-elf-objcopy -O binary $1.o $1.bin
xxd -e -c 4 $1.bin | cut -d' ' -f2 > $1.hex
