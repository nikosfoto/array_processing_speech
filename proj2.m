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
[s5, fs] = audioread('datasets/clean_speech.wav');  % Target source

% Pad the shorter signals with zeros
max_length = max([length(s1), length(s2), length(s3), length(s4), length(s5)]);
s1 = [s1; zeros(max_length - length(s1), 1)];
s2 = [s2; zeros(max_length - length(s2), 1)];
s3 = [s3; zeros(max_length - length(s3), 1)];
s4 = [s4; zeros(max_length - length(s4), 1)];
s5 = [s5; zeros(max_length - length(s5), 1)];
S = cat(2, s1, s2, s3, s4, s5);

% Convolve the impulse responses for each source - microphone pair
signal_length = max_length;
signals_sources_mics = zeros(signal_length, 5, 4);
for i = 1:NUM_SOURCES
    for j = 1:NUM_MICROPHONES
        signals_sources_mics(:, i, j) = conv(S(:,i), H{i}(j,:), "same");
    end
end

% Superposition from all sources at each microphone:
signals_mics = squeeze(sum(signals_sources_mics, 2));

% Now we're trying to isolate source 5 (target)...





