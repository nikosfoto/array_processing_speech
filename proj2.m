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

% Making the length of the whole recording one min and adding the clean
% part at the end
scaling_factor = 2;
max_length = fs*50;  % 60 seconds
% length of noisy part
noisy_length_n = max_length - length(s5);

% making all segments the same length
s1 = [s1; s1(1:max_length-length(s1))];
s2 = [s2; s2(1:max_length-length(s2))];
s3 = s3(1:max_length);
s4 = [s4; s4(1:max_length-length(s4))];

% adding the speech to the last part of the total duration
s5 = [zeros(max_length-length(s5), 1); scaling_factor*s5];
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

noise_end_time = noisy_length_n/fs;  % in seconds
noise_frame_end = noise_end_time * fs*2/N;

% Empirical cross PSD
alpha = 0.5;
K = size(F,1);
L = size(T,1);
Rx = zeros(NUM_MICROPHONES, NUM_MICROPHONES);
Rn = zeros(NUM_MICROPHONES, NUM_MICROPHONES);
S = zeros(K, L);
for k = 1:K
    for l = 1:L
        if l==1
            vec_x = X(k,1,:);
            Rx = vec_x(:)*vec_x(:)';
            Rn = vec_x(:)*vec_x(:)';
        else
            vec_x = X(k,l,:);
            Rx = alpha*Rx + (1-alpha)* vec_x(:)*vec_x(:)';
            if l < noise_frame_end
                Rn = alpha*Rn + (1-alpha)* vec_x(:)*vec_x(:)';
            else
                Rn = Rn_prev;
            end
        end
        [a,~] = estimate_a(Rx, Rn);
        inv_Rx = pinv(Rx);
        w = inv_Rx * a /(a'*inv_Rx*a);
        S(k,l) = w'*vec_x(:); 
        Rn_prev= Rn; 
    end
end

% Now we're trying to isolate source 5 (target)...

[s, t] = istft(S, fs, Window=hamming(N), OverlapLength=N/2, FFTLength=N);





