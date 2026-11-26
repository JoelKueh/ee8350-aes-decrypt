%% AES-128/192/256 Testbench (reads vectors.tsv)
clear; clc;

tsv_file = 'vectors.tsv';
addpath('src');

% Force column 4 (Hex) to string so all-digit values like 0000... keep leading zeros
T = readtable(tsv_file, ...
    'FileType',          'text', ...
    'Delimiter',         '\t', ...
    'ReadVariableNames', false, ...
    'Format',            '%s%s%d%s', ...
    'TextType',          'string');
T.Properties.VariableNames = {'Suite', 'Type', 'Bits', 'Hex'};

suites = unique(T.Suite, 'stable');
fprintf('Loaded %d suites from %s\n\n', numel(suites), tsv_file);

total_passed = 0;
total_vecs   = 0;

for s = 1:numel(suites)
    name = suites(s);
    rows = T(T.Suite == name, :);

    % Skip chained modes (CBC/CFB/OFB/CTR) that require an IV
    if any(rows.Type == "iv")
        fprintf('[SKIP] %-28s (requires IV / non-ECB mode)\n', name);
        continue;
    end

    kt_hex = rows.Hex(rows.Type == "kt");
    pt_hex = rows.Hex(rows.Type == "pt");
    ct_hex = rows.Hex(rows.Type == "ct");

    if isempty(kt_hex) || isempty(pt_hex) || isempty(ct_hex)
        fprintf('[SKIP] %-28s (missing kt, pt, or ct)\n', name);
        continue;
    end

    K  = hex_to_states(kt_hex);
    PT = hex_to_states(pt_hex);
    CT = hex_to_states(ct_hex);

    key_bits = size(K, 2) * 32;  % 128, 192, or 256
    N = max([size(K, 3), size(PT, 3), size(CT, 3)]);

    for i = 1:N
        key_i = K(:, :, min(i, size(K, 3)));
        pt_i  = PT(:, :, min(i, size(PT, 3)));
        ct_i  = CT(:, :, min(i, size(CT, 3)));

        RK    = KeyExpand(key_i);
        P_out = Decrypt(ct_i, RK);
        C_out = Encrypt(pt_i, RK);

        assert(isequal(P_out, pt_i), '%s (AES-%d) vector %d: Decrypt mismatch', name, key_bits, i);
        assert(isequal(C_out, ct_i), '%s (AES-%d) vector %d: Encrypt mismatch', name, key_bits, i);
    end

    total_passed = total_passed + 1;
    total_vecs   = total_vecs + N;
    fprintf('[PASS] %-28s [AES-%d] (%d/%d vectors)\n', name, key_bits, N, N);
end

fprintf('\nSummary: %d/%d suites passed (%d total blocks verified)\n', ...
    total_passed, numel(suites), total_vecs);

%% Helper: Convert string array of hex literals into 4xNumColsxN uint8 matrices
function states = hex_to_states(hex_col)
    N        = numel(hex_col);
    num_cols = strlength(hex_col(1)) / 8;  % 32->4, 48->6, 64->8 columns
    states   = zeros(4, num_cols, N, 'uint8');

    for i = 1:N
        bytes = uint8(sscanf(hex_col(i), '%2x'));
        states(:, :, i) = reshape(bytes, 4, num_cols);
    end
end
