clc; clear;

% Specify the paths to the files
savedDir = 'saved/';

% Load the saved files
fileList = dir(fullfile(savedDir, '*.wav'));
numFiles = numel(fileList);

% Define problem variables
NUM_SOURCES = 5;
NUM_MICROPHONES = 4;

% Load impulse respones and audio files (same fs)
H = struct2cell(load('impulse_responses.mat'));
[s1, ~] = audioread('datasets/babble_noise.wav');
[s2, ~] = audioread('datasets/clean_speech_2.wav');
[s3, ~] = audioread('datasets/Speech_shaped_noise.wav');
[s4, ~] = audioread('datasets/aritificial_nonstat_noise.wav');
[s5, fs] = audioread('datasets/clean_speech.wav');  % Target source

clean = s5;
clean_length = length(clean);

% Making the length of the whole recording 40 secs and add the clean
% part at the end
max_length = fs*40;

% length of noisy part
noisy_length_n = max_length - length(s5);

% Making all segments the same length
s1 = [s1; s1(1:max_length-length(s1))];
s2 = [s2; s2(1:max_length-length(s2))];
s3 = s3(1:max_length);
s4 = [s4; s4(1:max_length-length(s4))];
s5 = [zeros(max_length-length(s5), 1); s5];
S = cat(2, s1, s2, s3, s4, s5);

% Convolve the impulse responses for each source - microphone pair
signals_sources_mics = zeros(max_length, 5, 4);
for i = 1:NUM_SOURCES
    for j = 1:NUM_MICROPHONES
        signals_sources_mics(:, i, j) = conv(S(:,i), H{i}(j,:), "same");
    end
end

% Superposition from all sources at each microphone:
signals_mics = squeeze(sum(signals_sources_mics, 2));

% Calculate target signal at microphone 1
clean_mic1 = conv(clean, H{5}(1,:), "same");

% Original SNR before processing
snrOriginal = 20*log10( norm(clean_mic1) / norm(signals_mics(end-clean_length+1:end,1)-clean_mic1) );

% Display the original SNR
fprintf('Original SNR between clean speech and microphone 1: %.2fdB\n\n', snrOriginal);

% Calculate STOI for each saved file
for i = 1:numFiles
    % Load the current file
    filePath = fullfile(savedDir, fileList(i).name);
    [processed_signal, ~] = audioread(filePath);
    
    % Scale down
    processed_signal = processed_signal / 100;

    % Calculate STOI
    stoiValue = stoi(clean_mic1, processed_signal, fs);

    % Calculate SNR for each saved file
    snrValue = 20*log10( norm(clean_mic1) / norm(processed_signal - clean_mic1) );
    
    % Display the STOI value
    fprintf('STOI between clean speech and %s: %.5f\n', fileList(i).name, stoiValue);

    % Display the SNR value
    fprintf('SNR between clean speech and %s: %.2fdB\n\n', fileList(i).name, snrValue);
end