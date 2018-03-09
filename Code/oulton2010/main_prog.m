%**************************************************************
% MAIN_PROG - Solves the neoclassical model with a random walk
% TFP solved in class in EC860.
%
% Code by Ryan Chahrour, Boston College, 2014
%**************************************************************

clear all

current_dir = pwd;
cd ../.. % go up 2 levels
base_path = pwd;
cd(current_dir)
addpath(base_path)

%Load Parameters
param = parameters;

%Compute the first-order coefficiencients of the model
[fyn, fxn, fypn, fxpn] = model(param);

%Compute the transition and policy functions, using code by
%Stephanie Schmitt-Groh� and Mart�n Uribe (and available on their wedsite.)
[gx,hx]=gx_hx_alt(fyn,fxn,fypn,fxpn);

save('gxhx.mat', 'gx', 'hx')

%Eigenvalues of hx
disp('Computing eigenvalues of hx');
disp(eig(hx))

% IRFs
% Positions of the shocks in shock vector:
nvar = size(gx,1) + size(gx,2);
nshocks = size(hx,1);
pos_K = 1; % shock to K stock
pos_S = 2; % shock to IT stock
pos_GAMC = 3; % a shock to TFP in final goods prod (= surprise tech shock)
pos_GAMI = 4; % IT productivity shock
x0 = [0 0 0 0]'; % impulse vector
T = 60;
IRFs = zeros(nvar, T, nshocks);
for s=1:nshocks
    x0(s) = 1;
    [IR, iry, irx]=ir(gx,hx,x0,T);
    IRFs(:,:,s) = IR'; % 
end

which_shock = [pos_K pos_S pos_GAMC pos_GAMC];
names = {'Capital', 'IT stock', 'TFP', 'IT productivity'};
varnames = {'YC', 'YI', 'C', 'IC', 'IT', 'W', 'RC', 'RI', 'H', 'H1', 'H2', 'KC1', 'KC2', 'KI1', 'KI2', ...
    'G', 'GI', 'GP', 'KC', 'KI', 'GAMC', 'GAMI'};
print_figs = 'no';
plot_single_simple_IRFs(IRFs,T,which_shock,names, varnames, print_figs)

