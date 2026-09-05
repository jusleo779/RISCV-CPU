.global _start
_start:
    lui  x1, 0x80000
loop:
    lw   x2, 4(x1)     # read switches
    sw   x2, 0(x1)     # write to LEDs
    j    loop