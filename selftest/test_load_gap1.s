.global _start
_start:
    addi x1, x0, 24
    addi x2, x0, 99
    addi x0, x0, 0 # spacing it out to force errors
    addi x0, x0, 0 # spacing it out to force errors
    sw x2, 0(x1)
    lw x4, 0(x1)
    addi x3, x0, 20
    add x5, x4, x4 

loop:
    j loop