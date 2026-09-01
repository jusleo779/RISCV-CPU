.global _start
_start:
    addi x1, x0, 4
    addi x2, x0, 16
    addi x3, x0, 10
    sw x3, 0(x1)
    lw x4, 0(x1)            # x4 is loaded with value at x1
    sw x4, 0(x2)            # x4 is a stored at x2 the next line (causes a hazard since called twice in a row)
    lw x5, 0(x2)
loop:
    j loop