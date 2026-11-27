
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
    unsigned char K[AES_KEY_BYTES];
    unsigned char C[16];
    unsigned char RoundKeys[AES_RK_BYTES];
    unsigned char P[16];

    Hector::registerInput("K", K);
    Hector::registerInput("C", C);
    Hector::registerOutput("P", P);

    Hector::beginCapture();
    KeyExpand(K, RoundKeys);
    Decrypt(C, RoundKeys, P);
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
