function RoundKeys = KeyExpand(K, NumRounds) %#codegen
	% AES Key Expansion transformation
	% Input:  4x4 (128-bit), 4x6 (192-bit), or 4x8 (256-bit) uint8 Key State Matrix
	% Output: 4x4x(NumRounds+1) Array of round keys

	coder.inline('never');
	assert(NumRounds == 10 || NumRounds == 12 || NumRounds == 14);

	% Compute the number of columns from the number of rounds
	NumCols = NumRounds - 6;
	NumWords = 4 * (NumRounds + 1);

	% Create initial array of words
	Words = zeros(4, NumWords, 'uint8');
	Words(:, 1:NumCols) = K;

	% Initial round constant
	rcon = uint8(1);

	% Compute each column of the word array
	for i = (NumCols+1):NumWords
		% Each column is XOR'd with the column before it
		temp = Words(:, i-1);

		if mod(i-1, NumCols) == 0
			% Perform special computation on the first column in every key
			temp = temp([2; 3; 4; 1]);
			temp = SubWord(temp);
			temp(1) = bitxor(temp(1), rcon);
			rcon = GfMul(rcon, uint8(2));
		elseif NumCols == 8 && mod(i-1, NumCols) == 4
			% Perform extra SubWord halfway through 256-bit keys
			temp = SubWord(temp);
		end

		% Update the new word based on the previous word and temp
		Words(:, i) = bitxor(Words(:, i-NumCols), temp);
	end

	% Slice the 4xNumWords array into 4x4 round keys
	RoundKeys = reshape(Words, 4, 4, NumRounds + 1);
end

function K_out = SubWord(K_in) %#codegen
	% AES Substitute Word transformation
	% Input:  4x1 Key State Column
	% Output: 4x1 Substituted State Column

	% SubWord uses SBox like Encryption but only on column 1
    K_out = zeros(4,1,'uint8');
    for i = 1:4
        K_out(i,1) = SBox(K_in(i,1));
    end
end
