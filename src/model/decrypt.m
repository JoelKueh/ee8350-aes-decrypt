
% =============================================================================
% Encrypt Implementation
% =============================================================================

function C = Encrypt(P, RoundKeys)
	% AES Encryption Algorithm
	% Input:  4x4 plaintext matrix (P) and list of 4x4 round key matrcies
	% Output: 4x4 encrypted ciphertext matrix (C)

    % Initial addition of K0
    S = AddRoundKey(P, RoundKeys(:,:,1));

    % Main encryption rounds: K1 up to K9
    for r = 2:10
        S = SubBytes(S);
        S = ShiftRows(S);
        S = MixColumns(S);
        S = AddRoundKey(S, RoundKeys(:,:,r));
    end

    % Final decryption round using K10 without MixColumns
    S = SubBytes(S);
    S = ShiftRows(S);
    S = AddRoundKey(S, RoundKeys(:,:,11));

    C = S;
end

function S_out = SubBytes(S_in)
    % AES SubBytes transformation
    % Input:  4x4 uint8 state matrix
    % Output: 4x4 uint8 substituted state matrix

    s_out = zeros(4,4,'uint8');
    for i = 1:4
        for j = 1:4
            S_out(i,j) = SBox(S_in(i,j));
        end
    end
end

function S_out = MixColumns(S_in)
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

function S_out = ShiftRows(S_in)
	% AES ShiftRows transformation
	% Input:  4x4 state matrix
	% Output: 4x4 shifted state matrix

	S_out = zeros(4, 4, 'uint8');
	for i = 1:4
		S_out(i,:) = circshift(S_in(i,:), -(i-1));
	end
end

% =============================================================================
% Decrypt Implementation
% =============================================================================

function P = Decrypt(C, RoundKeys)
	% AES Decryption Algorithm
	% Input:  4x4 ciphertext matrix (C) and list of 4x4 round key matrcies
	% Output: 4x4 decrypted plaintext (P)

    % Initial AddRoundKey using K10
    S = AddRoundKey(C, RoundKeys(:,:,11));

    % Main decryption rounds: K9 down to K1
    for r = 10:-1:2
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

function S_out = InvSubBytes(S_in)
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

function S_out = InvMixColumns(S_in)
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

function S_out = InvShiftRows(S_in)
	% AES ShiftRows transformation
	% Input:  4x4 state matrix
	% Output: 4x4 shifted state matrix

	S_out = zeros(4, 4, 'uint8');
	for i = 1:4
		S_out(i,:) = circshift(S_in(i,:), +(i-1));
	end
end

% =============================================================================
% Key Expand Implementation
% =============================================================================

function RoundKeys = KeyExpand(K)
	% AES Key Expansion transformation
	% Input:  4x4 Key State Matrix
	% Output: Array of round keys

	% Create initial array of round keys
	RoundKeys = zeros(4, 4, 11, 'uint8');
	RoundKeys(:,:,1) = K;

	% Array of Round Constants XOR'd into the first column
	rcon = uint8(1);

	% Compute the round Keys
	for r = 2:11
		% Compute the new first column
		temp = RoundKeys(:, 4, r-1);
		temp = circshift(temp, -1);
		temp = SubWord(temp);
		temp(1) = bitxor(temp(1), rcon)
		RoundKeys(:, 1, r) = bitxor(RoundKeys(:, 1, r-1), temp);

		% XOR the new firs column into the other columns
		RoundKeys(:, 2, r) = bitxor(RoundKeys(:, 2, r-1), RoundKeys(:, 1, r));
		RoundKeys(:, 3, r) = bitxor(RoundKeys(:, 3, r-1), RoundKeys(:, 2, r));
		RoundKeys(:, 4, r) = bitxor(RoundKeys(:, 4, r-1), RoundKeys(:, 3, r));
		
		% Increment the round constant by multiplying by 2 in the Galois Field
		rcon = GfMul(rcon, uint8(2));
	end
end

function K_out = SubWord(K_in)
	% AES Substitute Word transformation
	% Input:  4x1 Key State Column
	% Output: 4x4 Substituted State Column

	% SubWord uses SBox like Encryption but only on column 1
    K_out = zeros(4,1,'uint8');
    for i = 1:4
        K_out(i,1) = SBox(K_in(i,1));
    end
end

% =============================================================================
% Common AES Utility Functions (Galois Field Operations)
% =============================================================================

function output = GfInv(input)
	% Multiplicative 8-bit inverse in the Galois field
	% Input:  8-bit byte
	% Output: 8-bit byte

	% Special case for input == 0
	input = uint8(input);
    if input == 0
        output = uint8(0);
        return;
    end

	% Multiplication using GfMul to compute inverse
    output = uint8(1);
    for k = 1:254
        output = GfMul(output, input);
    end
end

function output = GfMul(a, b)
	% 8-bit Multiplication in the Galois field
	% Input:  8-bit byte
	% Output: 8-bit byte

	output = uint8(0);
	for k = 1:8
		% Add if the lowest multiplier bit is non-zero
		if bitand(b, uint8(1)) ~= 0
			output = bitxor(output, a);
		end

		% Shift the multiplicand to the left by 1
		high_bit = bitget(a, 8);
        a = bitshift(a, 1);

		% Modular reduction by the Galois field polynomial
        if high_bit
            a = bitxor(a, 0x1Bu8);
        end

		% Shift the multiplier to the right by 1
        b = bitshift(b, -1);
    end
end

function output = SBox(input)
	% AES S-box transformation
	% Input:  8-bit byte
	% Output: 8-bit substituted byte

	% Affine transformation matrix
	A = uint8([
		1 0 0 0 1 1 1 1;
        1 1 0 0 0 1 1 1;
        1 1 1 0 0 0 1 1;
        1 1 1 1 0 0 0 1;
        1 1 1 1 1 0 0 0;
        0 1 1 1 1 1 0 0;
        0 0 1 1 1 1 1 0;
        0 0 0 1 1 1 1 1
	]);

	% Constant vector
    C = uint8([1; 1; 0; 0; 0; 1; 1; 0]);

	% Compute the inverse of the byte in the Galois field.
	b = GfInv(input);

	% Convert the input into a bit vector
	bits = zeros(8, 1, 'uint8');
	for k = 1:8
		bits(k) = bitget(b, k);
	end

	% Affine transformation over GF(2)
	result = zeros(8, 1, 'uint8');
	for k = 1:8
		result(k) = mod(sum(A(k,:)'.*bits), 2);
	end
	result = bitxor(result, C);

	% Return the result
	output = uint8(0);
	for k = 1:8
		output = bitor(output, bitshift(result(k), k-1));
	end
end

function output = InvSBox(input)
	% AES Inverse S-box transformation
	% Input:  8-bit byte
	% Output: 8-bit substituted byte

	% Affine transformation matrix
	A = uint8([
		0 0 1 0 0 1 0 1;
		1 0 0 1 0 0 1 0;
		0 1 0 0 1 0 0 1;
		1 0 1 0 0 1 0 0;
		0 1 0 1 0 0 1 0;
		0 0 1 0 1 0 0 1;
		1 0 0 1 0 1 0 0;
		0 1 0 0 1 0 1 0
	]);

	% Constant vector
	C = uint8([1; 0; 1; 0; 0; 0; 0; 0]);

	% Convert the input into a bit vector
	bits = zeros(8, 1, 'uint8');
	for k = 1:8
		bits(k) = bitget(input, k);
	end

	% Affine transformation over GF(2)
	mapped = zeros(8, 1, 'uint8');
	for k = 1:8
		mapped(k) = mod(sum(A(k,:)'.*bits), 2);
	end
	mapped = bitxor(mapped, C);

	% Pack the bit vector back into an 8-bit integer
	packed = uint8(0);
	for k = 1:8
		packed = bitor(packed, bitshift(mapped(k), k-1));
	end

	% Compute the inverse of the byte in the Galois field.
	output = GfInv(packed);
end

function S_out = AddRoundKey(S_in, K_r)
	% AES AddRoundKey transformation
	% Input:  4x4 state matrix and 4x4 round key matrix
	% Output: 4x4 XOR result
	S_out = bitxor(S_in, K_r);
end
