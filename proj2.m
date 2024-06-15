clear; close; clc;

% Define problem variables
NUM_SOURCES = 5;
NUM_MICROPHONES = 4;

% Load impulse respones and audio file of interest
H = struct2cell(load('impulse_responses.mat'));
[y, fs] = audioread('datasets/clean_speech.wav');

% Convolve the impulse responses for each source - microphone pair
signal_length = size(y, 1);
signals_sources_mics = zeros(signal_length, 5, 4);
for i = 1:NUM_SOURCES
    for j = 1:NUM_MICROPHONES
        signals_sources_mics(:, i, j) = conv(y, H{i}(j,:), "same");
    end
end

% Superposition from each source each microphone:
signals_mics = squeeze(sum(signals_sources_mics, 2));

% Now we're trying to isolate source 5 (target)...
% Perform delay and sum beamforming





