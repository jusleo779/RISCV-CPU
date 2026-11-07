.global _start
_start:
    lui  x1, 0x80000        # x1 = 0x80000000
loop:
    lw   x2, 4(x1)          # x2 = switches
    andi x2, x2, 15         # keep the current 4 bits
    addi x3, x2, -8         # d = s - 8, range -8 to 7 (half numbers negative & half are positive)
    srai x4, x3, 29         # fills with copy of bit 31 (1 if d < 0, 0 otherwise). (should be 0000(+) and 1111(-))
    srli x5, x3, 29         # shifts the current bits by 29 bits where the 4th bit is filled 0 (for +/-)(0000(+) or 0111(-))
    slt x6, x4, x5          # compares if x4 is less than x5 (catches if the operations are swapped)
    or x6, x6, x5           # catches SRLI value bug (Make sure the value is the expected value not the wrong one)
    sw x6, 0(x1)            # writes to leds
    
    j loop
