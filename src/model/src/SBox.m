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
