.global _start
_start:
    addi x1, x0, 4
    addi x2, x0, 50
    addi x3, x0, 32
    sw x3, 0(x1)        
    lw x4, 0(x1)        # x4 loads the value at x1 (rd = memory[rs1 + offset])
    sw x2, 0(x4)        # x4 is the address for the stored value for x2 (memory[rs1 + offset] = rs2)(hazard)
    addi x5, x0, 32
    lw x6, 0(x5)        # calls the address of 32 which is the same store address of x4


loop:
    j loop