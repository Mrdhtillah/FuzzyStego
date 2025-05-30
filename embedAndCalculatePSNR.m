function embedAndCalculatePSNR(coverImagePath, secretDataPath, stegoImagePath)
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

    % Define thresholds for classification
    tL = 50;  % Threshold for Low intensity
    tML = 100; % Threshold for Medium-Low intensity
    tM = 150;  % Threshold for Medium intensity
    tMH = 200; % Threshold for Medium-High intensity

    % Initialize the stego image
    stegoImage = coverImage;

    % Initialize the embedded bits counter
    embeddedBitsCount = 0;

    % Start timer for embedding process
    tic;

    % Embed the secret data
    bitIndex = 1;
    for i = 1:size(coverImage, 1)
        for j = 1:size(coverImage, 2)
            pixelValue = coverImage(i, j);

            if pixelValue <= tL
                % L: Replace 3 LSBs
                if bitIndex + 2 <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    stegoImage(i, j) = bitset(stegoImage(i, j), 2, secretBits(bitIndex + 1));
                    stegoImage(i, j) = bitset(stegoImage(i, j), 3, secretBits(bitIndex + 2));
                    bitIndex = bitIndex + 3;
                    embeddedBitsCount = embeddedBitsCount + 3;  % Increment by 3 bits
                end

            elseif pixelValue > tL && pixelValue <= tML
                % ML: Replace 2 LSBs
                if bitIndex + 1 <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    stegoImage(i, j) = bitset(stegoImage(i, j), 2, secretBits(bitIndex + 1));
                    bitIndex = bitIndex + 2;
                    embeddedBitsCount = embeddedBitsCount + 2;  % Increment by 2 bits
                end

            elseif pixelValue > tML && pixelValue <= tM
                % M: Replace 1 LSB
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;  % Increment by 1 bit
                end

            elseif pixelValue > tM && pixelValue <= tMH
                % MH: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;  % Increment by 1 bit
                end

            else
                % H: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;  % Increment by 1 bit
                end
            end
        end
    end

    % Stop timer for embedding process
    embeddingTime = toc;

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
    fprintf('Embedding time: %.4f seconds\n', embeddingTime);
end

function saveStegoImage(stegoImage, outputFilePath)
    % Ensure the output folder exists
    [outputDir, ~, ~] = fileparts(outputFilePath);
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Save the stego image in TIFF format
    [~, ~, ext] = fileparts(outputFilePath);
    if ~strcmp(ext, '.tiff') && ~strcmp(ext, '.tif')
        outputFilePath = strcat(outputFilePath, '.tiff');
    end

    imwrite(stegoImage, outputFilePath, 'tiff');
    fprintf('Stego image saved as %s\n', outputFilePath);
end
