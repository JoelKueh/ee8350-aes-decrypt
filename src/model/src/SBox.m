function output = SBox(input) %#codegen
	% AES S-box transformation
	% Input:  8-bit byte
	% Output: 8-bit substituted byte

	% If this is MATLAB Coder, then compile to LUT
	if coder.target('MATLAB')
		output = sbox_matlab(input);
	else
		lut = coder.const(build_sbox_lut());
		output = lut(uint16(input) + uint16(1));
	end
end

function output = sbox_matlab(input)
	persistent SBOX_LUT
	if isempty(SBOX_LUT)
		SBOX_LUT = build_sbox_lut();
	end
	output = SBOX_LUT(uint16(input) + uint16(1));
end

function lut = build_sbox_lut()
	lut = zeros(1, 256, 'uint8');
	for v = 0:255
		lut(v + 1) = sbox_math(uint8(v));
	end
end

function output = sbox_math(input)
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
