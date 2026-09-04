.global _start
_start:
    lui x1,0x80000
    addi x2, x0, 5
    sw x2, 0(x1)
loop:
    j loop