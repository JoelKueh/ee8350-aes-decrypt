function S_out = AddRoundKey(S_in, K_r) %#codegen
	% AES AddRoundKey transformation
	% Input:  4x4 state matrix and 4x4 round key matrix
	% Output: 4x4 XOR result
	S_out = bitxor(S_in, K_r);
end
