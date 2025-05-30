% main.m
clc; clear;

% File paths (use your actual file names)
coverImagePath = 'Images/Baboon.tiff';
secretDataPath = 'Payload/10kb.txt';

% Output paths for stego images
stegoImagePath_Fuzzy = 'results/stego_fuzzy.tiff';
stegoImagePath_NoFuzzy = 'results/stego_nofuzzy.tiff';
stegoImagePath_Extractable = 'results/stego_extractable.tiff';

%% Fuzzy-based embedding
fprintf('\n--- Running Fuzzy Embedding ---\n');
embedAndCalculatePSNR(coverImagePath, secretDataPath, stegoImagePath_Fuzzy);

%% NoFuzzy embedding
fprintf('\n--- Running NoFuzzy Embedding ---\n');
embedAndCalculatePSNR_NoFuzzy(coverImagePath, secretDataPath, stegoImagePath_NoFuzzy);

%% Fuzzy-based with Extraction
fprintf('\n--- Running Fuzzy Embedding with Extraction ---\n');
embedAndCalculatePSNRAndExtract(coverImagePath, secretDataPath, stegoImagePath_Extractable);

%% Compression-based embedding
fprintf('\n--- Running Compression-based Embedding ---\n');
embedAndCalculatePSNRCompression(coverImagePath, secretDataPath);
