# This code was stolen from (with some modifications)
# http://www.emoticode.net/python/python-implementation-of-rc4-algorithm.html

import sys

def rc4_crypt( data , key ):
    
    S = range(256)
    j = 0
    out = []
    
    #KSA Phase
    for i in range(256):
        j = (j + S[i] + ord( key[i % len(key)] )) % 256
        S[i] , S[j] = S[j] , S[i]

    # for i in range(256):
    #    sys.stdout.write(chr(S[i]))
    
    #PRGA Phase
    i = j = 0
    for char in data:
        i = ( i + 1 ) % 256
        j = ( j + S[i] ) % 256
        S[i] , S[j] = S[j] , S[i]
        out.append(chr(ord(char) ^ S[(S[i] + S[j]) % 256]))
        
    return ''.join(out)

result = rc4_crypt( "\x00" * 100, "ABCDEFGHIJKLMNOP" )
print(result)
