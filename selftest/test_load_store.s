.global _start
_start:
    addi x5, x0, 100    # value to be stored
    addi x6, x0, 0      # base addresss
    sw   x5, 0(x6)      # store x5 at address x6
    lw   x7, 0(x6)      # load word at address x6 into x7

    addi x8, x0, 50    # value to be stored
    addi x9, x0, 100   # base address
    sw   x8, -4(x9)      # store x8
    lw   x10, -4(x9)     # load word at address x9 into x10

loop: 
    j loop