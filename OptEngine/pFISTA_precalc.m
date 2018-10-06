function [ S, L ] = pFISTA_precalc( H, Params )
%PFISTA_PRECALC Summary of this function goes here
%   Detailed explanation goes here
%

global VERBOSE 

%% Initialization
N = Params.N;               % Length of x

%% Calculate S
if VERBOSE >= 3; fprintf('S_calc: ');t2 = tic; end;
S = S_calc(H, N);
if VERBOSE >= 3; toc(t2); end;

%% Calculate the Lipschitz constant
if isempty(Params.L0)
    L = real(max(max(S)));
else
    L = Params.L;
end


%% Auxiliary functions
% -------------------------------------------------------------------------
%% Calculate A1 which is needed for the gradient calculation 
function S = S_calc(H, N)
% Step 0
H2  = diag( abs(diag(H)).^2 );

% Step 1: M^2 X 1 vector q
q  = ctranspose( LAH_I(H2, N) );

% Step 2: N^2 X 1 vector A1
A1 = LAH_H(q, 1, N);

% Step 3: Calculate eigenvalues sqrt(N) X sqrt(N) matrix (N eigenvalues)
S = fft2(reshape(A1, sqrt(N), sqrt(N)));        % 1/N ? - does not seem to affect reconstruction performance

%% Left AH: Implementation of A*Y = H*kron(F, F)*Y efficiently, using FFT operations
function X = LAH(Y, H)
% Determine dimensions
[My, Ny] = size(Y);
[Mh, Nh] = size(H);

X = H * vec(pfft2(reshape(Y, sqrt(My), sqrt(My)), sqrt(Mh), 'fft'));
% X = H * cell2mat( arrayfun(@(ii) vec(pfft2(reshape(full(Y(:, ii)), sqrt(My), sqrt(My)), sqrt(Mh), 'fft')), 1:Ny, 'UniformOutput', false) );

%% Left AH Hermitian: Implementation of A^H*Y = kron(F, F)^H*H^H*Y efficiently, using FFT operations
function X = LAH_H(Y, H, N)
% Determine dimensions
[My, Ny] = size(Y);

Z = H' * Y;

X = cell2mat( arrayfun(@(ii) vec(pfft2(reshape(Z(:, ii), sqrt(My), sqrt(My)), sqrt(N), 'fft_h')), 1:Ny, 'UniformOutput', false) );

%% Similar to LAH_H, only the output is a vector
function X = LAH_I(Y, N)
% Determine dimensions
[My, Ny] = size(Y);

X = arrayfun(@(ii) FirstElement(pfft2(reshape(full(Y(:, ii)), sqrt(My), sqrt(My)), sqrt(N), 'fft_h')), 1:Ny);

%% Take first element of a matrix
function a = FirstElement(Q)
a = Q(1, 1);

%% Vectorize a matrix
function v = vec( x )
v = x(:);








