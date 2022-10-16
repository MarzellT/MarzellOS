# Interrupt Test
This page documents the results of running different interrupts.

## QEMU
The following are results running QEMU.

### Int 13/AH=08h Get Drive Parameters
#### HD boot
| Register | Value |
|----------|-------|
| AH       | 0x0   |
| AL       | 0x0   |
| BL       | 0x0   |
| CH       | 0x0   |
| CL       | 0x3f  |
| DH       | 0xf   |
| DL       | 0x1   |

### Int 13/AH=41h/BX=55AAh INT 13 Extensions Installation Check
#### HD boot
| Register | Value  |
|----------|--------|
| AH       | 0x30   |
| AL       | 0x0    |
| DH       | 0x0    |
| BX       | 0xaa55 |
| CX       | 0x7    |

### Int 13/AH=42h Extended Read
Works as expected as long as disk address packet is correct.
Make sure that especially DS:SI is set correctly.
