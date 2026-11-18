.global _start
_start:
    addi x1, x0, 5
    addi x2, x0, 10
    blt x1, x2, jump
    ebreak              # when blt passes and ebreak is called before jump then halted failed

jump:
    addi x3, x0, 10
    ebreak

