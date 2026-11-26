%% AES-128 Auto-Discovering SV Testbench
clear; clc;

sv_file = 'aes_vectors.sv';  % Path to your SystemVerilog file

% Read file once and strip both // and /* */ comments
txt = fileread(sv_file);
txt = regexprep(txt, '//[^\n]*', '');
txt = regexprep(txt, '/\*.*?\*/', '');

% Auto-discover all 128-bit suite prefixes (automatically skips 192/256-bit keys)
toks   = regexp(txt, 'logic\s+\[(?:0:127|127:0)\]\s+(\w+)_kt\b', 'tokens');
suites = unique(cellfun(@(c) c{1}, toks, 'UniformOutput', false), 'stable');

fprintf('Found %d 128-bit test suites in %s\n\n', numel(suites), sv_file);

total_passed = 0;
total_vecs   = 0;

for s = 1:numel(suites)
    name = suites{s};
    K  = parse_sv_vectors(txt, [name '_kt']);
    PT = parse_sv_vectors(txt, [name '_pt']);
    CT = parse_sv_vectors(txt, [name '_ct']);

    % Skip if any required array is missing
    if isempty(K) || isempty(PT) || isempty(CT)
        fprintf('[SKIP] %s (missing _kt, _pt, or _ct)\n', name);
        continue;
    end

    N = size(PT, 3);
    for i = 1:N
        key_i = K(:, :, min(i, size(K, 3)));
        RK    = KeyExpand(key_i);

        P_out = Decrypt(CT(:, :, i), RK);
        C_out = Encrypt(PT(:, :, i), RK);

        assert(isequal(P_out, PT(:, :, i)), '%s vector %d: Decrypt mismatch', name, i);
        assert(isequal(C_out, CT(:, :, i)), '%s vector %d: Encrypt mismatch', name, i);
    end

    total_passed = total_passed + 1;
    total_vecs   = total_vecs + N;
    fprintf('[PASS] %-28s (%d/%d vectors)\n', name, N, N);
end

fprintf('\nSummary: %d/%d suites passed (%d total blocks verified)\n', ...
    total_passed, numel(suites), total_vecs);

%% Helper: Parse 128-bit hex literals from preprocessed SV text
function states = parse_sv_vectors(txt, var_name)
    pat = ['\<' var_name '\>\s*(?:\[[^\]]*\])?\s*=\s*([^;]+);'];
    tok = regexp(txt, pat, 'tokens', 'once');
    if isempty(tok)
        states = [];
        return;
    end

    % Match 128'h... (handles optional underscores like 128'h0001_0203...)
    hex_list = regexp(tok{1}, '128''h([0-9a-fA-F_]+)', 'tokens');
    N = numel(hex_list);
    states = zeros(4, 4, N, 'uint8');

    for i = 1:N
        clean_hex = strrep(hex_list{i}{1}, '_', '');
        bytes = uint8(sscanf(clean_hex, '%2x'));
        states(:, :, i) = reshape(bytes, 4, 4);
    end
end
