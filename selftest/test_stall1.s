.global _start
_start:
    addi x1, x0, 24
    addi x2, x0, 99
    sw x2, 0(x1)        # store x2 into x1
    lw x3, 0(x1)        # load x1 that was saved in data memory into x3 
    addi x4, x3, 8      # needs x3 to execute which creates hazard since it isn't ready 
   
loop:
    j loop
