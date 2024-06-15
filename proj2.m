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

% Pad the shorter signals with zeros and scale clean signal
scaling_factor = 2;
% lengths = [length(s1), length(s2), length(s3), length(s4), length(s5)];
% disp(lengths);
% max_length = max(lengths);
max_length = length(s5);
s1 = [s1; zeros(max_length - length(s1), 1)];
s2 = s2(1:max_length);
s3 = s3(1:max_length);
s4 = s4(1:max_length);
s5 = scaling_factor*s5;
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

% Perform STFT
N = 320;   % 20ms or alternatively N=256 for 16ms
[X,F,T] = stft(signals_mics, fs, Window=hamming(N), OverlapLength=N/2, FFTLength=N);

% Empirical cross PSD
alpha = 0.5;
K = size(F,1);
L = size(T,1);
Rx = zeros(K, L, NUM_MICROPHONES, NUM_MICROPHONES);
for k = 1:K
    vec_x = X(k,1,:);
    Rx(k,1,:,:) = vec_x(:)*vec_x(:)';
    for l = 2:L
        vec_x = X(k,l,:);
        Rx(k,l,:,:) = alpha*squeeze(Rx(k,l-1,:,:)) + (1-alpha)* vec_x(:)*vec_x(:)';
    end
end

% Now we're trying to isolate source 5 (target)...





