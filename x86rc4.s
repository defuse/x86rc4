# RC4 Cipher in 73 bytes of x86.
# Peter Ferrie
# Oct 23, 2014

# Based on RC4 Cipher in 104 bytes of x86 by Taylor Hornby

.intel_syntax noprefix
.globl _start

.text

# void compute_rc4(char *buf)
# Where buf has the following weird format:
#  buf[0..3] = length of stream output.
#  buf[4..19] = the key
#  buf[20..275] = empty bytes (used for RC4 state)
#  buf[276...276+length] = the keystream (output)
# Output length MUST be at least 1 byte.
.global compute_rc4
compute_rc4:

    # We're getting called by a C function, so save all the registers.
    pushad

    # Make ESI point to buf (+32 for pushad, +4 for return address).
    mov esi, DWORD PTR [esp + 32 + 4]

    # Set ecx to the address where we should stop writing key bytes.
    mov ecx, DWORD PTR [esi]                    # (length)

    # Now make ESI point to the RC4 state.
    add esi, 4 + 16
    # Make EDI also point to the RC4 state.
    mov edi, esi

# Initialization (Part 1).

    # Fill the state with K[i] = i.
    # We do this in forwards order.
    # Loop eax = 0, 1, ..., 255

    xor eax, eax

start_fill:
    # We're using this loop also to add 256 to edi (see above)

    # K[eax] = al
    stosb

    # If we haven't reached 256, loop again.
    inc al
    jnz start_fill

# Initialization (Part 2).
    # Shuffle the state according to the key. 

    # I'd zero eax here, but we don't have to, since the loop above terminates
    # with eax == 0.
    # eax will hold the key index (always eax == ebx % 16)

    xor ebx, ebx

zero_edx:
    # edx will hold j
    cdq

# Loop ebx = 0, 1, 2, ... 255
loop_start:
    pushfd

    # Conditionally increment ebx (mod 256)
    adc bl, bh

    # Increment the key index (mod 16)
    mov al, bl
    and al, 0xF

    # j = j + K[i]
    add dl, BYTE PTR [ESI + ebx]

    popfd
    jb skip_key

    # j = (j + K[i] + key[i]) % 256
    add dl, BYTE PTR [ESI + eax - 16]

    clc

skip_key:
    # Note: This preserves the zeroness of the 3 most-signifigant bytes of EDX,
    # which is exactly what we want.

    # Swap bytes K[i] and K[j] (K[ebx] and K[edx]).
    mov al, BYTE PTR [ESI + edx]
    xchg al, BYTE PTR [ESI + ebx]
    mov BYTE PTR [ESI + edx], al

    jb stream_start

    # Increment ebx (mod 256)
    inc bl
    # If ebx was 255, it will now be 0, because overflow.
    # So if it's zero, we should stop the loop.
    jnz loop_start

    stc
    jb zero_edx

# Keystream Computation

    # Again, ordinarily we'd have to zero ebx, but it's already zero when the
    # previous loop ends, so we don't have to.

    # In the following, EBX holds the i variable.
    # EDX is j.

    # We make a space-saving assumption that the length is at least one, so that
    # this loop body will always execute at least once. So, be careful if you
    # are using this with a user-supplied length, it could overflow your buffer.

stream_start:
    # Output K[ (K[i] + K[j]) % 256 ]
    mov al, BYTE PTR [ESI + ebx]                # eax = K[i]
    add al, BYTE PTR [ESI + edx]                # eax = K[i] + K[j]
    mov al, BYTE PTR [ESI + eax]                # eax = K[(K[i] + K[j]) % 256]
    stosb                                       # Output the byte.

    stc

    # If ecx is zero, we're at the end of the output space.
    loop loop_start
stream_end:

    popad
    ret

# Notes:

# TODO: Make it use the stack for the RC4 state

