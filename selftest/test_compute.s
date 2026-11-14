.global _start
_start:
    lui  x1, 0x80000        # x1 = 0x80000000
loop:
    lw   x2, 4(x1)          # x2 = switches
    andi x2, x2, 15         # keep the current 4 bits
    addi x3, x2, -8         # d = s - 8, range -8 to 7 (half negative, half positive)
    srai x4, x3, 29         # fill with copies of bit 31: x4 = 0xFFFFFFFF if d < 0, 0 otherwise (low 4 bits 1111 / 0000)
    srli x5, x3, 29         # fill with 0s: x5 = 7 if d < 0, 0 otherwise (low 4 bits 0111 / 0000)
    slt  x6, x4, x5         # x6 = 1 if x4 < x5 (signed). Catches SRAI/SRLI swapped
    add  x6, x6, x5         # ADD, not OR: OR hid SRA-as-SRL (break experiment). x6 = 8 if d < 0, 0 otherwise
    blt  x3, x0, neg        # taken if d < 0 (signed; bltu x3, x0 would never be taken)
    add  x6, x6, x3         # not taken: x6 = 0 + d = 0..7 (sw 1000 -> 0000 ... sw 1111 -> 0111)
    j    done               # ...then jump OVER the taken code

neg:                        # taken path: sw 0000 (d = -8) -> 1111 ... sw 0111 (d = -1) -> 1000
    sub  x6, x6, x3         # x6 = 8 - d = 9..16 (subtracting a negative adds)
    addi x6, x6, -1         # shift 9..16 down to 8..15. Without it, d = -8 gives 16 = 0x10: bit 4 can't show
                            # on 4 LEDs, so it reads 0000 and collides with sw 1000. 8..15 is free because
                            # the not-taken path only produces 0..7

done:
    sw   x6, 0(x1)          # LEDs = x6[3:0]
    j    loop               # read the switches again