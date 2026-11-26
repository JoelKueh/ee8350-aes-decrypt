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
