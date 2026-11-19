.global _start
_start:
    lui  x1, 0x11223          # x1 = 0x11223000
    addi x1, x1, 0x344        # x1 = 0x11223344 (background, every byte different)

    addi x2, x0, 24           # word at 24 covers addresses 24..27
    sw   x1, 0(x2)            # mem[24..27] = 44 33 22 11
    addi x3, x0, 0xAB         # x3 = 0x000000AB
    sb   x3, 1(x2)            # address 25 only: 33 -> AB
    lw   x10, 0(x2)           # spec 0x1122AB44 (other 3 bytes survive)

    addi x4, x0, 28           # word at 28 covers addresses 28..31
    sw   x1, 0(x4)            # mem[28..31] = 44 33 22 11
    lui  x5, 0xC              # x5 = 0x0000C000 (0xB + 1, see addi below)
    addi x5, x5, -273         # -273 = -0x111: 0xC000 - 0x111 = 0x0000BEEF
                              # (0xEEF has bit 11 set, so addi would sign-extend it;
                              #  use the negative form and bump lui by 1)
    sh   x5, 2(x4)            # addresses 30,31: 22 11 -> EF BE
    lw   x11, 0(x4)           # spec 0xBEEF3344 (low half survives)

    addi x6, x0, 32           # word at 32 covers addresses 32..35
    lui  x7, 0x80018          # x7 = 0x80018000 (0x80017 + 1, see addi below)
    addi x7, x7, -100         # -100 = -0x64: 0x80018000 - 0x64 = 0x80017F9C
                              # (0xF9C has bit 11 set, same trick as above)
                              # bytes: 32=9C 33=7F 34=01 35=80
    sw   x7, 0(x6)
    lb   x12, 0(x6)           # 0x9C, top bit 1 -> 0xFFFFFF9C
    lbu  x13, 0(x6)           # 0x9C, zero-fill -> 0x0000009C
    lb   x14, 1(x6)           # 0x7F, top bit 0 -> 0x0000007F (lane select, no sign)
    lh   x15, 2(x6)           # 0x8001, top bit 1 -> 0xFFFF8001
    lhu  x16, 2(x6)           # 0x8001, zero-fill -> 0x00008001

loop:
    j    loop                 # j-to-self: testbench waits for this
