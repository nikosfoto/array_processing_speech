function a_hat = estimate_a(Rx, Rn)
[~,D,Q] = eig(Rx, Rn);
% Rs_hat = Q(:,1)*(D(1,1)-1)*Q(:,1)';
[D, ind] = sort(D);
Q = Q(:, ind);
a_hat = Q(:,1);
end