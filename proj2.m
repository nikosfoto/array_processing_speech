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

% Making the length of the whole recording one min and adding the clean
% part at the end
scaling_factor = 1;
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

%noise_end_time = noisy_length_n/fs;  % in seconds
%noise_frame_end = noise_end_time * fs*2/N;

noisy_frames = findnoise(s5, fs, N/2);


%%
% Empirical cross PSD
alpha = 0.2;
K = size(F,1);
L = size(T,1);
Rx = zeros(NUM_MICROPHONES, NUM_MICROPHONES);
Rn = zeros(NUM_MICROPHONES, NUM_MICROPHONES);
S = zeros(K, L);
mu = 0.5; 
for k = 1:K
    for l = 1:L
        if l==1
            vec_x = X(k,1,:);
            Rx = vec_x(:)*vec_x(:)';
            Rn = vec_x(:)*vec_x(:)';
        else
            vec_x = X(k,l,:);
            Rx = alpha*Rx + (1-alpha)* vec_x(:)*vec_x(:)';
            if noisy_frames(l) == 1
                Rn = alpha*Rn + (1-alpha)* vec_x(:)*vec_x(:)';
            else
                Rn = Rn_prev;
            end
        end
        [a,sigma_s] = estimate_a(Rx, Rn);

        % Multi channel
        %inv_R = pinv(Rn);
        %w = (sigma_s*inv_Rn*a)/(sigma_s*(a'*inv_Rn*a)+mu);

        % MVDR
        %inv_R = pinv(Rx);
        % w = (inv_R *a ) / (a'*inv_R * a);

        % signal distortion weighted
        e = [1;0;0;0];
        Rs = sigma_s* a * a'; 
        w = (Rs + mu*Rn)\ Rs *e;

        S(k,l) = w'*vec_x(:); 
        Rn_prev= Rn; 
    end
end

% Now we're trying to isolate source 5 (target)...
S(isnan(S))=0;
[s, t] = istft(S, fs, Window=hamming(N), OverlapLength=N/2, FFTLength=512);


%%
hold("on")
plot(s5)
plot(real(s))
hold("off")

%%
stoi(s5, real(s), fs) 
