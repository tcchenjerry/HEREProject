function [M_zca, P_zca] = whiten_trans(x, epsth)

% find data whitening transform
M_zca = mean(x);
x = x - repmat(M_zca,[size(x,1),1]);
C = cov(x);

[U S V] = svd(C);
P_zca = V * diag(1./sqrt(diag(S) +epsth)) * U';

end