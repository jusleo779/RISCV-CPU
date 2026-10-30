.global _start
_start:
    addi x1, x0, 5
    addi x2, x0, 10
    add  x3, x1, x2      # x3 should = 15
    addi x4, x0, -1      # x4 should = 0xFFFFFFFF (sign-extend check)
    sub  x5, x3, x1       # x5 should = 10
loop:
    j loop
