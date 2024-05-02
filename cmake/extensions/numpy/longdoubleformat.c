#include <stdio.h>
#include <string.h>

#define repcmp(z) (memcmp((const char *)&foo.x, z, sizeof(foo.x)) == 0)

const struct {
    char before[16];
    long double x;
    char after[8];
} foo = {{'\0'}, -123456789.0, {'\0'}};

int main(void) {
    switch (sizeof(foo.x)) {
        case 8: {
            if (repcmp(
                    ((const char[]){0000, 0000, 0000, 0124, 0064, 0157, 0235, 0301}))) {
                fprintf(stdout, "IEEE_DOUBLE_LE");
                return 0;
            }
            if (repcmp(
                    ((const char[]){0301, 0235, 0157, 0064, 0124, 0000, 0000, 0000}))) {
                fprintf(stdout, "IEEE_DOUBLE_BE");
                return 0;
            }
            fprintf(stdout, "UNKNOWN");
            return 1;
        }
        case 12: {
            if (repcmp(((const char[]){0000, 0000, 0000, 0000, 0240, 0242, 0171, 0353,
                                       0031, 0300, 0000, 0000}))) {
                fprintf(stdout, "INTEL_EXTENDED_12_BYTES_LE");
                return 0;
            }
            if (repcmp(((const char[]){0300, 0031, 0000, 0000, 0353, 0171, 0242, 0240,
                                       0000, 0000, 0000, 0000}))) {
                fprintf(stdout, "MOTOROLA_EXTENDED_12_BYTES_BE");
                return 0;
            }
            fprintf(stdout, "UNKNOWN");
            return 1;
        }
        case 16: {
            if (repcmp(
                    ((const char[]){0000, 0000, 0000, 0000, 0240, 0242, 0171, 0353,
                                    0031, 0300, 0000, 0000, 0000, 0000, 0000, 0000}))) {
                fprintf(stdout, "INTEL_EXTENDED_16_BYTES_LE");
                return 0;
            }
            if (repcmp(
                    ((const char[]){0300, 0031, 0326, 0363, 0105, 0100, 0000, 0000,
                                    0000, 0000, 0000, 0000, 0000, 0000, 0000, 0000}))) {
                fprintf(stdout, "IEEE_QUAD_BE");
                return 0;
            }
            if (repcmp(
                    ((const char[]){0000, 0000, 0000, 0000, 0000, 0000, 0000, 0000,
                                    0000, 0000, 0100, 0105, 0363, 0326, 0031, 0300}))) {
                fprintf(stdout, "IEEE_QUAD_LE");
                return 0;
            }
            if (repcmp(
                    ((const char[]){0000, 0000, 0000, 0124, 0064, 0157, 0235, 0301,
                                    0000, 0000, 0000, 0000, 0000, 0000, 0000, 0000}))) {
                fprintf(stdout, "IBM_DOUBLE_DOUBLE_LE");
                return 0;
            }
            if (repcmp(
                    ((const char[]){0301, 0235, 0157, 0064, 0124, 0000, 0000, 0000,
                                    0000, 0000, 0000, 0000, 0000, 0000, 0000, 0000}))) {
                fprintf(stdout, "IBM_DOUBLE_DOUBLE_BE");
                return 0;
            }
            fprintf(stdout, "UNKNOWN");
            return 1;
        }
    }
}