.global _start
_start:
    addi x1, x0, 5
    fence r, r
loop:
    j loop
