function P = Decrypt(C, RoundKeys, NumRounds) %#codegen
	% AES Decryption Algorithm
	% Input:  4x4 ciphertext matrix (C) and list of 4x4 round key matrcies
	% Output: 4x4 decrypted plaintext (P)

	coder.inline('never');
	assert(NumRounds == 10 || NumRounds == 12 || NumRounds == 14);

    % Initial AddRoundKey using K10
    S = AddRoundKey(C, RoundKeys(:,:,NumRounds+1));

    % Main decryption rounds: K9 down to K1
    for r = NumRounds:-1:2
        S = InvShiftRows(S);
        S = InvSubBytes(S);
        S = AddRoundKey(S, RoundKeys(:,:,r));
        S = InvMixColumns(S);
    end

    % Final decryption round using K0
    S = InvShiftRows(S);
    S = InvSubBytes(S);
    S = AddRoundKey(S, RoundKeys(:,:,1));

    P = S;
end

function S_out = InvSubBytes(S_in) %#codegen
    % AES SubBytes transformation
    % Input:  4x4 uint8 state matrix
    % Output: 4x4 uint8 substituted state matrix

    S_out = zeros(4,4,'uint8');
    for i = 1:4
        for j = 1:4
            S_out(i,j) = InvSBox(S_in(i,j));
        end
    end
end

function S_out = InvMixColumns(S_in) %#codegen
	% AES MixColumns transofrmation
	% Input:  4x4 state matrix
	% Output: 4x4 transformed state matrix

    % Column mixing matrix
	M = uint8([
    	14 11 13  9;
    	 9 14 11 13;
    	13  9 14 11;
    	11 13  9 14
	]);
    S_out = zeros(4, 4, 'uint8');

    % Multiply each column by M in the Galois field
    for j = 1:4
        column = S_in(:,j);
        for i = 1:4
            value = uint8(0);
            for k = 1:4
                value = bitxor(value, ...
                    GfMul(M(i,k), column(k)));
            end
            S_out(i,j) = value;
        end
    end
end

function S_out = InvShiftRows(S_in) %#codegen
	% AES ShiftRows transformation
	% Input:  4x4 state matrix
	% Output: 4x4 shifted state matrix

	S_out = zeros(4, 4, 'uint8');
	for i = 1:4
		S_out(i,:) = circshift(S_in(i,:), +(i-1));
	end
end
