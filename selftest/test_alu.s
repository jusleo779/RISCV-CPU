cat > test_alu.s << 'EOF'
.global _start
_start:
    addi x1, x0, 12
    addi x2, x0, 10
    and  x3, x1, x2
    or   x4, x1, x2
    xor  x5, x1, x2
    addi x6, x0, -1
    addi x7, x0, 1
    slt  x8, x6, x7
    sltu x9, x6, x7
    addi x10, x0, -16
    srli x11, x10, 4
    srai x12, x10, 4
    slli x13, x2, 2
    addi x14, x0, 5
    addi x15, x0, 10
    add  x16, x14, x15
    addi x17, x0, -1
    sub  x18, x16, x14
loop:
    j loop
EOF