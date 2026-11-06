    lui  x1, 0x80000        # x1 = 0x80000000, MMIO base
loop:
    lw   x2, 4(x1)          # x2 = switches
    andi x2, x2, 15         # keep 4 bits (load-use, gap 0)
    addi x3, x2, -8         # d = s - 8, range -8..7
   