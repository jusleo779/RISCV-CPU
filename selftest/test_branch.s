.global _start
_start:
    addi x1, x0, 5
    beq x0, x0, target
    addi x1, x0, 99
    target:
    addi x2, x0, 7

    addi x5, x0, -1
    addi x6, x0, 1

    #blt test
    addi x7, x0, 5        
    blt  x5, x6, skip1
    addi x7, x0, 99       
    skip1:
    addi x8, x0, 10
     
    #bltu test
    addi x10, x0, 5
    bltu x5, x6, skip2
    addi x10, x0, 99       
    skip2:
    addi x11, x0, 15

    # bne test
    addi x12, x0, 3
    addi x13, x0, 3
    addi x14, x0, 5
    bne  x12, x13, skip3    
    addi x14, x0, 99
    skip3:
    addi x15, x0, 20

    #bgeu test
    addi x16, x0, 10
    bgeu x5, x6, skip4
    addi x16, x0, 99
    skip4:
    addi x17, x0, 25

    #bge test
    addi x18, x0, 15
    bge x5, x6, skip5
    addi x18, x0, 99
    skip5:
    addi x19, x0, 30

    addi x20, x0, 3
    count_loop:
        addi x20, x20, -1
        bne x20, x0, count_loop
    addi x21, x0, 42

    


loop:
    j loop
    