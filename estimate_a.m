function [a_hat, sigma_s] = estimate_a(Rx, Rn)
% Generalized eigenvalue Decomposition of Rn^-1 * Rx
[~,D,Q] = eig(Rx, Rn);

% Sorting the eigenvalues
eig_vals = spdiags(D);
[eig_vals_sorted, ind] = sort(eig_vals, 'descend');

% Assigning the principal eigenvalue to sigma_s and vector to a_hat
a_hat = Q(:,ind(1));
sigma_s = eig_vals_sorted(1)-1;
end