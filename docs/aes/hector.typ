#set page(
  width: 8.5in,
  height: 11in,
  margin: 1in,
)

#show raw: set text(size: 7pt)
#show raw.where(block: true): it => block(
  fill: luma(240),
  inset: 4pt,
  radius: 4pt,
  width: 100%,
  it
)

#set document(title: "EE8350 - HECTOR Data Path Solver", author: ("Joel Kuehne <kuehn348@umn.edu>"))
#title()
_Joel Kuehne \<kuehn348\@umn.edu\>_

= Data Path Equivalence

== Overview

- All about transaction level equivalence
  - In a C model, a transaction is computed in zero time
  - In an RTL model, a transaction may be computed over multiple cycles
  - In pipelined designs, multiple transactions may be in flight at once
  - Transaction level equivalence means equivalent data processing in different pipeline models
- Fundamentally requires bit accuracy
- Must have fixed maximum latency
  - Works based on unrolling the datapath over the target latency
  - Latency on the order of a few 10s of cycles is usually fine, but 100s of cycles is too much
- DPV only verifies a single transaction
  - To prove that multiple transactions work, you must prove that the design returns to a valid initial state
  - If there are no assumptions about initial state, then a proof for one transaction is a proof for a stream


= HECTOR

== Configuration

- Specialized engine for proving sum-of-products lemmas over a dataflow graph (DFG)
- These must be sum of products lemmas at the top level
  - The LHS is some verilog expression
  - The RHS is a combination of constants, primary inputs, and cutpoints.
    - There are some oddities with supported syntaxes (have to investigate)
- Highly configurable
  - Encodings - Allows you to select the encoding style for multipliers to match the RTL
  - Modes - Different solver modes to try

This is recommended as an initial starting point that designers should try

```
run_all_hdps_options hdps_proof -modes 0 -encodings gradeschool -abstypes def_abstraction -rrtypes false -hdps_resource 600 -solver_resource 100
```

== Phases

- Started - Initial state
- IO_verified - Inputs and outputs of the design have been correlated against the lemma arguments
- Pp_term_verified - The partial product of one of the expressions has been verified
- Pp_verified - All partial products have been verified
- Cpa_partial_verified - Lemma verification is partially completed
- Cpa_verified - HDPS has successfully verified the lemma
