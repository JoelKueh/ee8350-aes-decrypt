{
    sub(/\/\/.*/, "")  # Strip single-line // comments
}

/logic[ \t]+\[[0-9]+:[0-9]+\][ \t]+[A-Za-z0-9_]+_(kt|pt|ct|iv)/ {
    # Extract bit width from [0:127], [191:0], [0:255], etc.
    match($0, /\[[0-9]+:[0-9]+\]/)
    rng = substr($0, RSTART + 1, RLENGTH - 2)
    split(rng, b, ":")
    bits = (b[1] > b[2] ? b[1] - b[2] : b[2] - b[1]) + 1
    hex_len = bits / 4

    # Split variable name into Suite and Type (kt, pt, ct, iv)
    match($0, /[A-Za-z0-9_]+_(kt|pt|ct|iv)/)
    var   = substr($0, RSTART, RLENGTH)
    type  = substr(var, length(var) - 1, 2)
    suite = substr(var, 1, length(var) - 3)
    active = 1
}

active {
    line = $0
    # Extract all sized (128'h...) and unsized ('h0) hex literals
    while (match(line, /([0-9]+)?'h[0-9a-fA-F_]+/)) {
        tok = substr(line, RSTART, RLENGTH)
        sub(/^.*'h/, "", tok)
        gsub(/_/, "", tok)
        while (length(tok) < hex_len) tok = "0" tok
        printf "%s\t%s\t%d\t%s\n", suite, type, bits, tok
        line = substr(line, RSTART + RLENGTH)
    }
    if ($0 ~ /;/) active = 0
}
