%% Generate HECTOR-friendly C++ for KeyExpand, Encrypt, and Decrypt
clear; clc;

addpath('src');

% Configure coder to use HECTOR-friendly techniques
cfg = coder.config('lib');
cfg.TargetLang                    = 'C++';
cfg.GenCodeOnly                   = true;
cfg.EnableDynamicMemoryAllocation = false;
cfg.SupportNonFinite              = false;
cfg.GenerateExampleMain           = 'DoNotGenerate';
cfg.GenerateReport                = true;
cfg.FilePartitionMethod           = 'MapMFileToCFile';

% AES-128 (4x4 key, 11 round keys, 10 rounds)
codegen -config cfg -d codegen/lib/aes_128 -o aes_128 ...
	KeyExpand -args {coder.typeof(uint8(0), [4 4]), coder.Constant(uint8(10))} ...
	Encrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 11]), coder.Constant(uint8(10))} ...
	Decrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 11]), coder.Constant(uint8(10))}
pack_standalone('codegen/lib/aes_128');

% AES-192 (4x6 key, 13 round keys, 12 rounds)
codegen -config cfg -d codegen/lib/aes_192 -o aes_192 ...
	KeyExpand -args {coder.typeof(uint8(0), [4 6]), coder.Constant(uint8(12))} ...
	Encrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 13]), coder.Constant(uint8(12))} ...
	Decrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 13]), coder.Constant(uint8(12))}
pack_standalone('codegen/lib/aes_192');

% AES-256 (4x8 key, 15 round keys, 14 rounds)
codegen -config cfg -d codegen/lib/aes_256 -o aes_256 ...
	KeyExpand -args {coder.typeof(uint8(0), [4 8]), coder.Constant(uint8(14))} ...
	Encrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 15]), coder.Constant(uint8(14))} ...
	Decrypt   -args {coder.typeof(uint8(0), [4 4]), coder.typeof(uint8(0), [4 4 15]), coder.Constant(uint8(14))}
pack_standalone('codegen/lib/aes_256');

% Helper function to make sure that MATLAB packages all necessary header files
function pack_standalone(outDir)
	% Read the buildInfo manifest
	outDir = fullfile(pwd, outDir);
	buildInfo = loadBuildInfo(fullfile(outDir, 'buildInfo.mat'));

	% Send the necessary files to a zip
	pkgZip = fullfile(outDir, 'standalone.zip');
	pkgDir = fullfile(outDir, 'standalone');
	packNGo(buildInfo, 'packType', 'flat', 'minimalHeaders', true, 'fileName', pkgZip);

	% Unpack the zip to a folder and delete the old copy
	if isfolder(pkgDir)
		rmdir(pkgDir, 's');
	end
	unzip(pkgZip, pkgDir);
	delete(pkgZip);
end
