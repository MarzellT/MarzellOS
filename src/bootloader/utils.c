//
// Created by tobias on 01.02.23.
//

#include <stdint.h>

char* ascii_lut = "0123456789";

/* convert an unsigned 32 bit int to a string and store it at dest */
uint32_t int_to_str(uint32_t value, char* dest) {
    char buf[10];  // 2^32 is at max 10 digits;

    uint8_t i = 0;
    do {
        buf[i] = ascii_lut[value%10];
        value = value/10;
        i++;
    } while (value);

    uint8_t j = 0;
    for (; j < i; j++) {
        dest[j] = buf[i - j - 1];
    }

    dest[i] = 0;
    return i+1;
}
