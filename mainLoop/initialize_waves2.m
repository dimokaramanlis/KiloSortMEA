clear W

Ncomps = 4;
W(:,1) = rez.ops.wPCA(:,1);
W(:,2) = rez.ops.wPCA(:,1);
W(:,3) = circshift(rez.ops.wPCA(:,1), -1);
W(:,4) = circshift(rez.ops.wPCA(:,1), 1);

W = single(W);

W  = W(:, repmat([1 2 3 4 1 2 3 4], ceil(Nfilt/(2 * Ncomps)), 1)) + .1 * my_conv(randn(nt0, 2 * Ncomps*ceil(Nfilt/(2 * Ncomps)), 'single')', 5)';
W = W(:, 1:Nfilt);

xc = rez.xc; yc = rez.yc;

C2C = (xc(:) - xc(:)').^2 + (yc(:) - yc(:)').^2;
C2C =  sqrt(C2C);

[~, isort] = sort(C2C, 'ascend');

iC= isort(1:20, :);
sigma = 60;
ix = iC + [0:Nchan:Nchan^2-1];
mask = exp( - C2C(ix).^2/(2*sigma^2));

mask = mask ./ (1e-3 + sum(mask.^2,1)).^.5;

maskAll = zeros (Nchan, Nchan);

for ii = 1:Nchan
    maskAll (ii, iC(:, ii)) = mask(:, ii);
end

U = repmat(maskAll, 1, ceil(Nfilt/Nchan));
U = U(:, 1:Nfilt);

U = U .* (1 + .05 * randn(size(U)));
U(abs(U)<.01) = 0;
U = single(U);


Uinit = normc(U);
Winit = normc(W);
