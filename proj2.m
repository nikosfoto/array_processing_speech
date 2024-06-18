clear; close; clc;

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

% Making the length of the whole recording 40 seconds and adding the clean
% part at the end, and making all the noise signals the same length
max_length = fs*40;  % 40 seconds
s1 = [s1; s1(1:max_length-length(s1))];
s2 = [s2; s2(1:max_length-length(s2))];
s3 = s3(1:max_length);
s4 = [s4; s4(1:max_length-length(s4))];

% adding the speech to the last part of the total duration
s5 = [zeros(max_length-length(s5), 1); s5];
S = cat(2, s1, s2, s3, s4, s5);
%%
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
%%
% Perform STFT
N = 320;   % 20ms or alternatively N=256 for 16ms
[X,F,T] = stft(signals_mics, fs, Window=hamming(N), OverlapLength=N/2, FFTLength=512);

% Finding the noisy frames
noisy_frames = findnoise(s5, fs, N/2);
%%

% Finding the empirical cross PSD, and filter for each frequency bin and
% time frame

% Parameters to be set
alpha = 0.5;
mu = 0.7; 
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
            Rx = alpha*Rx_prev + (1-alpha)* vec_x(:)*vec_x(:)';
            if noisy_frames(l) == 1
                Rn = alpha*Rn_prev + (1-alpha)* vec_x(:)*vec_x(:)';
            else
                Rn = Rn_prev;
            end
        end
        [a,sigma_s] = estimate_a(Rx, Rn);
        % Select one of the following filters

        % % MVDR
        %inv_R = pinv(Rx);
        %w = (inv_R *a ) / (a'*inv_R * a);

        % % Multi channel
        % inv_R = pinv(Rn);
        % w = (sigma_s*inv_R*a)/(sigma_s*(a'*inv_R*a)+1);

        % Signal distortion weighted
        e = [1;0;0;0];
        Rs = sigma_s* a * a'; 
        w = pinv(Rs + mu*Rn)* Rs*e;

        S(k,l) = w'*vec_x(:); 
        Rn_prev = Rn;
        Rx_prev = Rx;
    end
end

% Performing inverse STFT
S(isnan(S))=0;
[s, t] = istft(S, fs, Window=hamming(N), OverlapLength=N/2, FFTLength=512);


%%
% PLotting the clean and recovered signals
hold("on")
plot(s5)
plot(real(s))
hold("off")

%%
% Finding the STOI score
pure_s5_mic1 = conv(s5(end-577655+1:end), H{5}(1,:), "same");
stoi(pure_s5_mic1, real(s(end-577655+1:end)), fs) 
%%
% Finding the SNR 
SNR_received = 20*log10( norm(pure_s5_mic1) / norm(signals_mics(end-577655+1:end,1)-pure_s5_mic1))
SNR_output = 20*log10( norm(pure_s5_mic1) / norm(real(s(end-577655+1:end))-pure_s5_mic1))
