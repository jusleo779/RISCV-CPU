.global _start
_start:
    addi x1,x0, 24
    addi x2,x0, 99
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    sw x2, 0(x1)
    lw x3, 0(x1)
    addi x0, x0, 0
    addi x0, x0, 0
    add x4, x3, x3

loop:
    j loop