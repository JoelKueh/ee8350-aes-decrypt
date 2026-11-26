function output = GfInv(input) %#codegen
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
