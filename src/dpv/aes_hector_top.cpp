
#include "Hector.h"
#include "KeyExpand.h"
#include "Decrypt.h"

#ifndef AES_KEY_BYTES
#define AES_KEY_BYTES 16
#endif

#ifndef AES_RK_BYTES
#define AES_RK_BYTES 176
#endif

void hector_wrapper()
{
    unsigned char K_raw[AES_KEY_BYTES];
    unsigned char C_raw[16];
    unsigned char P_raw[16];

    unsigned char K[AES_KEY_BYTES];
    unsigned char C[16];
    unsigned char RoundKeys[AES_RK_BYTES];
    unsigned char P[16];

    Hector::registerInput("K", K_raw);
    Hector::registerInput("C", C_raw);
    Hector::registerOutput("P", P_raw);

    Hector::beginCapture();

    // Reverse the byte ordering of K and C
    // - FIPS-197 expects LSB first (big-endian) ordering
    // - HECTOR unpacks MSB first (little-endian)
    for (int i = 0; i < AES_KEY_BYTES; i++)
        K[i] = K_raw[AES_KEY_BYTES - 1 - i];
    for (int i = 0; i < 16; i++)
        C[i] = C_raw[15 - i];

    KeyExpand(K, RoundKeys);
    Decrypt(C, RoundKeys, P);

    // Reverse the byte ordering of P
    for (int i = 0; i < 16; i++)
        P_raw[i] = P[15 - i];

    Hector::endCapture();
}

// Attempting all at once formal proof because of good intermediate equivalences
// void hector_decrypt()
// {
//     unsigned char C[16];
//     unsigned char RoundKeys[AES_RK_BYTES];
//     unsigned char NumRounds;
//     unsigned char P[16];
// 
//     Hector::registerInput("C", C);
//     Hector::registerInput("RoundKeys", RoundKeys);
//     Hector::registerOutput("P", P);
// 
//     Hector::beginCapture();
//     Decrypt(C, RoundKeys, P);
//     Hector::endCapture();
// }
// 
// void hector_key_expand()
// {
//     unsigned char K[32];
//     unsigned char RoundKeys[AES_RK_BYTES];
// 
//     Hector::registerInput("C", K);
//     Hector::registerOutput("RoundKeys", RoundKeys);
// 
//     Hector::beginCapture();
//     KeyExpand(K, RoundKeys);
//     Hector::endCapture();
// }
