clear W

tps = [1 5 10 25 40 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  1 0   0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,1) = my_conv(fs, 1);

tps = [1 5 10 25 40 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  1  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,2) = my_conv(fs, 1);

tps = [1 5 10 15 25 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  1  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,3) = my_conv(fs, 1);

tps = [1 5 10 20 30 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  1  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,4) = my_conv(fs, 1);

tps = [1 5 10 25 40 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  0 0   0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,5) = my_conv(fs, 1);

tps = [1 5 10 25 40 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  0  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,6) = my_conv(fs, 1);

tps = [1 5 10 15 25 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  0  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,7) = my_conv(fs, 1);

tps = [1 5 10 20 30 50 61];
tps = round(tps * nt0/61);
vs  = [0 0  0 -2  0  0  0];
fs= interp1(tps, vs, 1:nt0, 'linear', 'extrap');
W(:,1,8) = my_conv(fs, 1);


W = (single(W));
W = squeeze(W);

W  = W(:, repmat([1 2 3 4 1 2 3 4], ceil(Nfilt/8), 1)) + .1 * my_conv(randn(nt0, 8*ceil(Nfilt/8), 'single')', 5)';


xc = rez.xc; yc = rez.yc;

C2C = (xc(:) - xc(:)').^2 + (yc(:) - yc(:)').^2;
C2C =  sqrt(C2C);

[~, isort] = sort(C2C, 'ascend');

iC = isort(1:min(20,Nchan), :);
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
