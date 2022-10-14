SECTIONS {
    . = 0x500;
    /* .text : {
        *;
    }
    here we want to get the address
    to be correct after the relocate
    . -= 0x7c00;
    . += 0x500;
    .text : {
        * (after_relocate);
    }
    */
}