function n_frames = findnoise(s5, fs, ov)

windowDuration = 0.06; % seconds
numWindowSamples = round(windowDuration*fs);
win = hamming(numWindowSamples,'periodic');

percentOverlap = 25;
overlap = round(numWindowSamples*percentOverlap/100);

mergeDuration = 0.2;
mergeDist = round(mergeDuration*fs);

idx = detectSpeech(s5,fs,"Window",win,"OverlapLength",overlap,"MergeDistance",mergeDist);
frames = ones(size(s5));
for i = 1:length(idx)
    frames(idx(i,1 ): idx(i,2)) = 0;
end

n_frames = zeros((length(s5)/ ov) -1, 1);

for i = 1:(length(s5)/ ov) -1
    n_frames(i) = sum(frames((i-1)*ov + 1 : i*ov));

end

n_frames(n_frames == 160) = 1;  % Set elements equal to 160 to 1
n_frames(n_frames ~= 1) = 0;  % Set all other

end