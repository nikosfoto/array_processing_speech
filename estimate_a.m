function [a_hat, sigma_s] = estimate_a(Rx, Rn)
[~,D,Q] = eig(Rx, Rn);
eig_vals = spdiags(D);
[eig_vals_sorted, ind] = sort(eig_vals, 'descend');
a_hat = Q(:,ind(1));
% Rs_hat = a_hat*(D(1,1)-1)*a_hat';
sigma_s = eig_vals_sorted(1)-1;
end