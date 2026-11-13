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
    add x6, x6, x5          # ADD, not OR: OR hid SRA-as-SRL (break experiment). Also catches wrong SRLI value
    blt  x3, x0, neg        # compares if it is taken it will go to neg and do the operations
    add  x6, x6, x3         # not taken runs this (led values 0000 --> 0111 where inputs 1000 = 0 and 1111 = 7)

    j done                  # ...then jumps OVER the taken code

neg: # saying from the led values 1000 --> 1111 is -1 = 1000 and -8 = 1111, where inputs are 0000 = -8 to 0111 = -1
    sub x6, x6, x3       # only the taken path runs these two (8 - (-#))
    addi x6, x6, -1      # prevents overlap of 0000 for the not taken and taken because the value 8 was never used
                         # in the leds which is why we are able to subtract

done:
    sw x6, 0(x1)
    j  loop               # read the switches again

