function embedAndCalculatePSNRAndExtract(coverImagePath, secretDataPath, stegoImagePath)
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
                    embeddedBitsCount = embeddedBitsCount + 3;
                end

            elseif pixelValue > tL && pixelValue <= tML
                % ML: Replace 2 LSBs
                if bitIndex + 1 <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    stegoImage(i, j) = bitset(stegoImage(i, j), 2, secretBits(bitIndex + 1));
                    bitIndex = bitIndex + 2;
                    embeddedBitsCount = embeddedBitsCount + 2;
                end

            elseif pixelValue > tML && pixelValue <= tM
                % M: Replace 1 LSB
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;
                end

            elseif pixelValue > tM && pixelValue <= tMH
                % MH: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;
                end

            else
                % H: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                    embeddedBitsCount = embeddedBitsCount + 1;
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

    % Extract secret data and measure extraction time
    [extractedBits, extractionTime] = extractSecretDataAndMeasureTime(stegoImagePath);

    % Display the embedding and extraction results
    fprintf('Embedding Results:\n');
    fprintf('PSNR: %.4f dB\n', psnrValue);
    fprintf('MSE: %.4f\n', mseValue);
    fprintf('SSIM: %.4f\n', ssimValue);
    fprintf('Total embedded bits: %d bits\n', embeddingCapacityBits);
    fprintf('Embedding capacity: %.4f bits per pixel (bpp)\n', embeddingCapacityBpp);
    fprintf('Embedding time: %.4f seconds\n\n', embeddingTime);

    fprintf('Extraction Results:\n');
    fprintf('Extraction time: %.4f seconds\n', extractionTime);
    fprintf('Number of extracted bits: %d\n', length(extractedBits));
end


function extractSecretDataAndMeasureTime(stegoImagePath) =
    % Start the timer to measure extraction time
    tic;
    
    % Load the stego image
    stegoImage = imread(stegoImagePath);

    % Initialize variables
    secretBits = [];  % To store extracted secret bits

    % Define thresholds for classification
    tL = 50;    % Threshold for Low intensity
    tML = 100;  % Threshold for Medium-Low intensity
    tM = 150;   % Threshold for Medium intensity
    tMH = 200;  % Threshold for Medium-High intensity

    % Loop through each pixel in the stego image
    for i = 1:size(stegoImage, 1)
        for j = 1:size(stegoImage, 2)
            pixelValue = stegoImage(i, j);

            % Classify the pixel intensity and extract secret bits
            if pixelValue <= tL
                % Low intensity: Extract 3 LSBs
                secretBits = [secretBits, bitget(pixelValue, 1), bitget(pixelValue, 2), bitget(pixelValue, 3)];
            elseif pixelValue > tL && pixelValue <= tML
                % Medium-Low intensity: Extract 2 LSBs
                secretBits = [secretBits, bitget(pixelValue, 1), bitget(pixelValue, 2)];
            elseif pixelValue > tML && pixelValue <= tM
                % Medium intensity: Extract 1 LSB
                secretBits = [secretBits, bitget(pixelValue, 1)];
            elseif pixelValue > tM && pixelValue <= tMH
                % Medium-High intensity: Use modulo to extract bit
                secretBits = [secretBits, mod(pixelValue, 2)];
            else
                % High intensity: Use modulo to extract bit
                secretBits = [secretBits, mod(pixelValue, 2)];
            end
        end
    end

    % Stop the timer and calculate the extraction time
    extractionTime = toc;
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
