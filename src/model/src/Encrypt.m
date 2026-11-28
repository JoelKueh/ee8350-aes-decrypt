function C = Encrypt(P, RoundKeys, NumRounds) %#codegen
	% AES Encryption Algorithm
	% Input:  4x4 plaintext matrix (P) and list of 4x4 round key matrcies
	% Output: 4x4 encrypted ciphertext matrix (C)

	coder.inline('never');
	assert(NumRounds == 10 || NumRounds == 12 || NumRounds == 14);

    % Initial addition of K0
    S = AddRoundKey(P, RoundKeys(:,:,1));

    % Main encryption rounds: K1 up to K9
    for r = 2:NumRounds
        S = SubBytes(S);
        S = ShiftRows(S);
        S = MixColumns(S);
        S = AddRoundKey(S, RoundKeys(:,:,r));
    end

    % Final decryption round using K10 without MixColumns
    S = SubBytes(S);
    S = ShiftRows(S);
    S = AddRoundKey(S, RoundKeys(:,:,NumRounds+1));

    C = S;
end

function S_out = SubBytes(S_in) %#codegen
    % AES SubBytes transformation
    % Input:  4x4 uint8 state matrix
    % Output: 4x4 uint8 substituted state matrix

    S_out = zeros(4,4,'uint8');
    for i = 1:4
        for j = 1:4
            S_out(i,j) = SBox(S_in(i,j));
        end
    end
end

function S_out = MixColumns(S_in) %#codegen
	% AES MixColumns transofrmation
	% Input:  4x4 state matrix
	% Output: 4x4 transformed state matrix

    % Column mixing matrix
    M = uint8([
        2 3 1 1;
        1 2 3 1;
        1 1 2 3;
        3 1 1 2
    ]);
    S_out = zeros(4, 4, 'uint8');

    % Multiply each column by M in the Galois field
    for j = 1:4
        column = S_in(:,j);
        for i = 1:4
            value = uint8(0);
            for k = 1:4
                value = bitxor(value, GfMul(M(i,k), column(k)));
            end
            S_out(i,j) = value;
        end
    end
end

function S_out = ShiftRows(S_in) %#codegen
	% AES ShiftRows transformation
	% Input:  4x4 state matrix
	% Output: 4x4 shifted state matrix

	S_out = S_in;
	S_out(2, :) = S_in(2, [2 3 4 1]);
	S_out(3, :) = S_in(3, [3 4 1 2]);
	S_out(4, :) = S_in(4, [4 1 2 3]);
end
