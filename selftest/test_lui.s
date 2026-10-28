.global _start
_start:
    lui x1, 0x12345  # Correct value: 	0x12345000
    addi x2, x1, 50  # Correct value:   0x12345032
loop: 
    j loop