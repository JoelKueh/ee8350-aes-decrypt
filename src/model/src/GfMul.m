function output = GfMul(a, b) %#codegen
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
