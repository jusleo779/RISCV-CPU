.global _start
_start:
    lui x1, 0x12345
    auipc x2, 0x1000

loop:
    j loop