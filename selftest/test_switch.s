.global _start
_start:
    lui x1,0x80000
    lw x2, 4(x1)
loop:
    j loop