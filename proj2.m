clear; close; clc;

% Define problem variables
NUM_SOURCES = 5;
NUM_MICROPHONES = 4;

% Load impulse respones and audio files (same fs)
H = struct2cell(load('impulse_responses.mat'));
[s1, ~] = audioread('datasets/clean_speech_2.wav');
[s2, ~] = audioread('datasets/babble_noise.wav');
[s3, ~] = audioread('datasets/Speech_shaped_noise.wav');
[s4, ~] = audioread('datasets/aritificial_nonstat_noise.wav');
[s5, fs] = audioread('datasets/clean_speech.wav');

% Truncate all files to the same length
min_length = min([length(s1), length(s2), length(s3), ...
                  length(s4), length(s5)]);
S = cat(2, s1(1:min_length), s2(1:min_length), ...
    s3(1:min_length), s4(1:min_length), s5(1:min_length));

% Convolve the impulse responses for each source - microphone pair
signal_length = min_length;
signals_sources_mics = zeros(signal_length, 5, 4);
for i = 1:NUM_SOURCES
    for j = 1:NUM_MICROPHONES
        signals_sources_mics(:, i, j) = conv(S(:,i), H{i}(j,:), "same");
    end
end

% Superposition from each source at each microphone:
signals_mics = squeeze(sum(signals_sources_mics, 2));

% Now we're trying to isolate source 5 (target)...





