function embedAndCalculatePSNR_NoFuzzy(coverImagePath, secretDataPath, stegoImagePath)
    % Load the cover image
    coverImage = imread(coverImagePath);
    
    % Read the secret data from a text file
    fileID = fopen(secretDataPath, 'r');
    secretDataBits = fscanf(fileID, '%1d');
    fclose(fileID);
    
    % Convert secret text to its ASCII values and then to binary
    secretData = double(secretDataBits); % Convert to ASCII numeric values
    secretBits = dec2bin(secretData, 8) - '0';  % Convert to binary, 8 bits per character
    secretBits = secretBits(:)';  % Flatten to a row vector

    % Initialize the stego image
    stegoImage = coverImage;

    % Initialize the embedded bits counter
    embeddedBitsCount = 0;

    % Embed the secret data (uniform rule: replace 2 LSBs for all pixels)
    bitIndex = 1;
    for i = 1:size(coverImage, 1)
        for j = 1:size(coverImage, 2)
            pixelValue = coverImage(i, j);
            
            % Uniform embedding: Replace 2 LSBs
            if bitIndex + 1 <= length(secretBits)
                stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                stegoImage(i, j) = bitset(stegoImage(i, j), 2, secretBits(bitIndex + 1));
                bitIndex = bitIndex + 2;
                embeddedBitsCount = embeddedBitsCount + 2;  % Increment by 2 bits
            end
        end
    end

    % Save the stego image
    saveStegoImage(stegoImage, stegoImagePath);

    % Calculate PSNR, MSE, and SSIM
    psnrValue = psnr(stegoImage, coverImage);
    mseValue = immse(stegoImage, coverImage);
    ssimValue = ssim(stegoImage, coverImage);

    % Calculate embedding capacity (in bits and bits per pixel)
    totalPixels = numel(coverImage);
    embeddingCapacityBits = embeddedBitsCount;
    embeddingCapacityBpp = embeddingCapacityBits / totalPixels;

    % Display the results
    fprintf('PSNR: %.4f dB\n', psnrValue);
    fprintf('MSE: %.4f\n', mseValue);
    fprintf('SSIM: %.4f\n', ssimValue);
    fprintf('Total embedded bits: %d bits\n', embeddingCapacityBits);
    fprintf('Embedding capacity: %.4f bits per pixel (bpp)\n', embeddingCapacityBpp);
end

function saveStegoImage(stegoImage, outputFilePath)
    % Ensure the output file path has a .tiff extension
    [~, ~, ext] = fileparts(outputFilePath);
    if ~strcmp(ext, '.tiff') && ~strcmp(ext, '.tif')
        outputFilePath = strcat(outputFilePath, '.tiff');
    end
    
    % Save the stego image in TIFF format
    imwrite(stegoImage, outputFilePath, 'tiff');
    fprintf('Stego image saved as %s\n', outputFilePath);
end
