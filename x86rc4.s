# RC4 Cipher in 104 bytes of x86.
# Taylor Hornby
# Oct 23, 2014

# Based on this pseudocode:
# http://blog.cdleary.com/2009/09/learning-python-by-example-rc4/

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
    # Make EDI point to the output part of buf.
    mov edi, esi
    # This should be 4 + 16 + 256, but that's too big. Instead, we add 4 + 16
    # here then increment it once in each iteration of the next loop (which
    # iterates 256 times).
    add edi, 4 + 16

    # ESI points to: output_length[4] || key[16] || work_area[256] || output...

# Initialization (Part 1).

    # Fill the state with K[i] = i.
    # We do this in backwards order.
    # Loop ecx = 255, 254, ..., 0

    # Get 256 in ECX.
    xor ecx, ecx
    inc ecx
    shl ecx, 8

start_fill:
    # We're using this loop also to add 256 to edi (see above)
    inc edi

    # 255, 254, ... 0
    dec ecx

    # K[ecx] = ecx
    mov BYTE PTR [esi + 4 + 16 + ecx], cl

    # If we haven't reached zero, loop again.
    test ecx, ecx
    jnz start_fill

# Initialization (Part 2).
    # Shuffle the state according to the key. 

    # I'd zero ecx here, but we don't have to, since the loop above terminates
    # with ecx == 0.

    # edx will hold the key index (always edx == ecx % 16)
    xor edx, edx
    # eax will hold j
    xor eax, eax

# Loop ecx = 0, 1, 2, ... 255
loop_start:
    # j = j + K[i]
    add al, BYTE PTR [ESI + 4 + 16 + ecx]
    # j = (j + K[i] + key[i]) % 256
    add al, BYTE PTR [ESI + 4 + edx]

    # Note: This preserves the zeroness of the 3 most-signifigant bytes of EAX,
    # which is exactly what we want.

    # Swap bytes K[i] and K[j] (K[ecx] and K[eax]).
    call swap_eax_ecx_bytes_using_ebx

    # Increment the key index (mod 16)
    inc edx
    and edx, 0xF

    # Increment ecx (mod 256)
    inc cl
    # If ecx was 255, it will now be 0, because overflow.
    # So if it's zero, we should stop the loop.
    jnz loop_start
loop_end:


# Keystream Computation

    # Set edx to the address where we should stop writing key bytes.
    mov edx, edi
    add edx, DWORD PTR [esi]                    # (+ length)

    # Again, ordinarily we'd have to zero ecx, but it's already zero when the
    # previous loop ends, so we don't have to.

    # In the following, ECX holds the i variable.
    # EAX is j.
    xor eax, eax

    # We make a space-saving assumption that the length is at least one, so that
    # this loop body will always execute at least once. So, be careful if you
    # are using this with a user-supplied length, it could overflow your buffer.

stream_start:
    # i = (i + 1) % 256
    inc cl
    # j = (j + K[i]) % 256
    add al, BYTE PTR [ESI + 4 + 16 + ecx]

    # swap K[i] and K[j] (K[ecx] and K[eax])
    call swap_eax_ecx_bytes_using_ebx

    # Output K[ (K[i] + K[j]) % 256 ]
    xor ebx, ebx
    mov bl, BYTE PTR [ESI + 4 + 16 + ecx]       # ebx = K[i]
    add bl, BYTE PTR [ESI + 4 + 16 + eax]       # ebx = K[i] + K[j]
    mov bl, BYTE PTR [ESI + 4 + 16 + ebx]       # ebx = K[(K[i] + K[j]) % 256]
    mov BYTE PTR [edi], bl                      # Output the byte.

    inc edi
    # If edi made it to edx, we're at the end of the output space.
    cmp edx, edi
    jne stream_start
stream_end:

    popad
    ret

# Little subroutine that swaps K[eax] with K[ecx].
# It clobbers the EBX register.
swap_eax_ecx_bytes_using_ebx:
    mov bl, BYTE PTR [ESI + 4 + 16 + eax]
    xchg bl, BYTE PTR [ESI + 4 + 16 + ecx]
    mov BYTE PTR [ESI + 4 + 16 + eax], bl
    ret

# Notes:

# TODO: Make it compute_rc4(char *key, char *out, int length)
# TODO: Make it use the stack for the RC4 state

