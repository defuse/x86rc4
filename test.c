#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define OUTPUT_LENGTH 100

struct rc4struct {
    long length;
    unsigned long key[4];
    unsigned char state[256];
    unsigned char keystream[4];
} __attribute__((packed));

typedef struct rc4struct RC4;

extern int compute_rc4(char *buf);

int main(int argc, char **argv)
{
    if (argc != 2 || strlen(argv[1]) != 16) {
        printf("Usage: ./test <16 char key>\n");
        return 1;
    }
    RC4 *state = malloc(4 + 256 + OUTPUT_LENGTH);
    state->length = OUTPUT_LENGTH;
    strncpy((char *)state->key, argv[1], 16);
    compute_rc4((char *)state);
    int i = 0;
    for (; i < OUTPUT_LENGTH; i++) {
        printf("%c", state->keystream[i]);
    }
}
