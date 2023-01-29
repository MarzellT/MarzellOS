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

### Int 13/AX=E820h Query System Address Map
Works as expected.   
Resulting memory map:   

| Address            | Type |
|--------------------|------|
| 0x0000-09fc00      | 1    |
| 0x9fc00-A0000      | 2    |
| 0xf0000-100000     | 2    |
| 0x100000-0x7FE0000 | 1    |
| 0x7FE0000-8000000  | 2    |
