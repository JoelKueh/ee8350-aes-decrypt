%% Generate HECTOR-ready C++ for KeyExpand, Encrypt, and Decrypt
clear; clc;

addpath('src');

cfg = coder.config('lib');
cfg.TargetLang                    = 'C++';
cfg.GenCodeOnly                   = true;
cfg.EnableDynamicMemoryAllocation = false;
cfg.SupportNonFinite              = false;
cfg.GenerateExampleMain           = 'DoNotGenerate';
cfg.GenerateReport                = true;
cfg.FilePartitionMethod           = 'MapMFileToCFile'; % Emits KeyExpand.cpp, Encrypt.cpp, Decrypt.cpp

% Fixed-size input specifications
t_block      = coder.typeof(uint8(0), [4, 4]);
t_key        = coder.typeof(uint8(0), [4, 8]);
t_round_keys = coder.typeof(uint8(0), [4, 4, 15]);
t_u8         = coder.typeof(uint8(0)); % Used for NumCols (4/6/8) and Nr (10/12/14)

% Generate all three entry points into ./codegen/lib/aes_model/
codegen -config cfg -d codegen/lib/aes_model ...
    KeyExpand -args {t_key, t_u8} ...
    Encrypt   -args {t_block, t_round_keys, t_u8} ...
    Decrypt   -args {t_block, t_round_keys, t_u8}

