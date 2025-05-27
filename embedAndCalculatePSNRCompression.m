function embedAndCalculatePSNRCompression(coverImagePath, secretDataPath)
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
                end

            elseif pixelValue > tL && pixelValue <= tML
                % ML: Replace 2 LSBs
                if bitIndex + 1 <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    stegoImage(i, j) = bitset(stegoImage(i, j), 2, secretBits(bitIndex + 1));
                    bitIndex = bitIndex + 2;
                end

            elseif pixelValue > tML && pixelValue <= tM
                % M: Replace 1 LSB
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = bitset(pixelValue, 1, secretBits(bitIndex));
                    bitIndex = bitIndex + 1;
                end

            elseif pixelValue > tM && pixelValue <= tMH
                % MH: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                end

            else
                % H: Add secret data
                if bitIndex <= length(secretBits)
                    stegoImage(i, j) = pixelValue + bin2dec(num2str(secretBits(bitIndex)));
                    bitIndex = bitIndex + 1;
                end
            end
        end
    end

    % Calculate PSNR and SSIM before compression
    psnrValue = psnr(stegoImage, coverImage);
    ssimValue = ssim(stegoImage, coverImage);

    % Display the PSNR and SSIM values before compression
    fprintf('PSNR before compression: %.4f dB\n', psnrValue);
    fprintf('SSIM before compression: %.4f\n', ssimValue);

    % Compress the stego image using transform coding (DCT)
    compressedStegoImage = compressUsingDCT(stegoImage);
    
    % Convert compressed image back to uint8 to match the cover image class
    compressedStegoImage = uint8(compressedStegoImage);

    % Calculate PSNR and SSIM after compression
    psnrValueAfter = psnr(compressedStegoImage, coverImage);
    ssimValueAfter = ssim(compressedStegoImage, coverImage);

    % Display the PSNR and SSIM values after compression
    fprintf('PSNR after compression: %.4f dB\n', psnrValueAfter);
    fprintf('SSIM after compression: %.4f\n', ssimValueAfter);
end

% Function to compress image using Transformation Coding 
function compressedImage = compressUsingDCT(image)
    % Apply DCT block-wise
    blockSize = 8;  % Block size for DCT
    dctImage = blkproc(image, [blockSize blockSize], @dct2);  % Apply 2D DCT to each block

    % Quantize DCT coefficients
    quantizationMatrix = ones(blockSize, blockSize) * 20;  % Simplified quantization matrix
    quantizedImage = blkproc(dctImage, [blockSize blockSize], @(block) round(block ./ quantizationMatrix));
    
    % Dequantize to reconstruct
    dequantizedImage = blkproc(quantizedImage, [blockSize blockSize], @(block) block .* quantizationMatrix);
    
    % Apply inverse DCT block-wise to reconstruct the image
    compressedImage = blkproc(dequantizedImage, [blockSize blockSize], @idct2);  % Inverse 2D DCT
end
