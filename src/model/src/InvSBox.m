function output = InvSBox(input) %#codegen
	% AES Inverse S-box transformation
	% Input:  8-bit byte
	% Output: 8-bit substituted byte

	% If this is MATLAB Coder, then compile to LUT
	if coder.target('MATLAB')
		output = inv_sbox_matlab(input);
	else
		lut = coder.const(build_inv_sbox_lut());
		output = lut(uint16(input) + uint16(1));
	end
end

function output = inv_sbox_matlab(input)
	persistent INV_SBOX_LUT
	if isempty(INV_SBOX_LUT)
		INV_SBOX_LUT = build_inv_sbox_lut();
	end
	output = INV_SBOX_LUT(uint16(input) + uint16(1));
end

function lut = build_inv_sbox_lut()
	lut = zeros(1, 256, 'uint8');
	for v = 0:255
		lut(v + 1) = inv_sbox_math(uint8(v));
	end
end

function output = inv_sbox_math(input)
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
