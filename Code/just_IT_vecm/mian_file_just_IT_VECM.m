% main_file_just_IT.m  - implements a VECM to identify the effect of an IT
% shock alone as a shock that maximizes FEV IT on impact and has 0 impact
% effect on TFP
%
% Code by Marco Brianti and Laura Gati, Boston College, 2018
%**************************************************************

clear
close all

current_dir = pwd;
cd ../.. % go up 2 levels
base_path = pwd;
cd(current_dir)
addpath(base_path)

if exist([base_path '\Data'], 'dir')
      addpath([base_path '\Data']) %for Microsoft
else
      addpath([base_path '/Data']) %for Mac
end

tic

%Data Reading and Transformation
filename = 'dataset_main';
sheet    = 'Data';
range    = 'B1:W287';
warning off
[data, varnames] = read_data2(filename, sheet, range);
warning on
shocknames = {'IT Shock'};
varnames

% Find positions of shocks and of relative prices in a correct way
if sum(strcmp('Real SP', varnames))==1 % i.e. 'Real SP' exists as a variable
      pos_news = find(strcmp('Real SP', varnames));
elseif sum(strcmp('Michigan Index ', varnames))==1 % i.e. we use Mich for news
      pos_news = find(strcmp('Michigan Index ', varnames));
elseif sum(strcmp('SP deflated', varnames))==1 % i.e. we use SP deflated by GDPDEF for news
      pos_news = find(strcmp('SP deflated', varnames));
elseif sum(strcmp('SP deflated per capita', varnames))==1 % i.e. we use SP deflated by GDPDEF for news
      pos_news = find(strcmp('SP deflated per capita', varnames));
end
pos_IT = find(strcmp('Real IT Investment', varnames));
if find(strcmp('Relative Price', varnames)) > 0
      pos_rel_prices = find(strcmp('Relative Price', varnames));
elseif find(strcmp('Relative price PCE', varnames))
      pos_rel_prices = find(strcmp('Relative price PCE', varnames));
end


%Technical Parameters
max_lags        = 10;
nburn           = 0; %with the Kilian correction better not burning!!!
nsimul          = 20; %5000
nvar            = size(data,2);
sig1            = 0.75; % significance level
sig2            = 0.8; % a 2nd sig. level
H               = 100; %40; % horizon for generation of IRFs
h               = H; %40; % horizon for IRF plots
which_variable  = pos_IT; % select IT as the variable whose FEV we wanna max

%%Checking the number of lags over BIC, AIC, and HQ (see 'Lecture2M' in our folder)
[AIC,BIC,HQ] = aic_bic_hq(data,max_lags);
if AIC >= 4
      nlags = 2; % 2;
      warning(['AIC > 4, setting nlags to ', num2str(nlags) ])
else
      nlags = AIC;
end

[LR_MET LR_TT] = Johansen_Test(data, nlags);

%Run reduced form VECM
r = 1; %number of cointegrating vectors. If there is just one trend then...
%we have just one permanent shock and all the others shocks are temporary.
%This is the reason why we have nvar-1 cointegrating relationships.
[alph_hat,bet_hat,Pi,Gam_hat,res,sigma] = redu_VECM(data, nlags, r);

%Run structural VECM
diff_BBp_sigma = 1;
j = 0;
while diff_BBp_sigma >= 10^(-6)
      j = j + 1
      [B, Xi, A, check] = structural_VECM(alph_hat,bet_hat,Gam_hat,res,sigma,nlags,r);
      diff_BBp_sigma
end

% Implement the "just IT" ID strategy in a VAR
[impact, impact_IT_opt, gam_opt]  = just_IT_ID(which_variable,which_shock,B);

% Bootstrap
which_ID = 'just_IT';
which_correction = 'blocks'; % [none, blocks] --> Choose whether to draws residuals in blocks or not.
blocksize = 5; % size of block for drawing in blocks
% Add constant to beta matrix to work properly with the bootstrap code:
A  = [zeros(size(A,1),1) A];
[beta_tilde, data_boot2, beta_tilde_star] = ...
      bootstrap_with_kilian_VECM(A', nburn, res', ...
      nsimul, which_correction, blocksize,r);


% Get "bootstrapped A" nsimul times
for i_simul=1:nsimul
      %Run reduced form VECM
      [alph_hat_boot(:,:,i_simul),bet_hat_boot(:,:,i_simul),...
            Pi_boot(:,:,i_simul),Gam_hat_boot(:,:,i_simul),...
            res_boot(:,:,i_simul),sigma_boot(:,:,i_simul)] ...
            = redu_VECM(data_boot2(:,:,i_simul), nlags, r);
      %Run structural VECM
      [B_boot(:,:,i_simul), Xi_boot(:,:,i_simul), A_boot(:,:,i_simul)] ...
            = structural_VECM(alph_hat_boot(:,:,i_simul),bet_hat_boot(:,:,i_simul),...
            Gam_hat_boot(:,:,i_simul),res_boot(:,:,i_simul),sigma_boot(:,:,i_simul),...
            nlags,r);
      
      % Implement the "just IT" ID strategy in a VAR
      disp(['Iteration ' num2str(i_simul) ' out of ' num2str(nsimul)])
      [impact_boot(:,i_simul), ~, ~]  ...
            = just_IT_ID(which_variable,which_shock,B_boot(:,:,i_simul));
end

%Creating a fake matrix for the IRF of the point estimation
fake_impact = zeros(nvar,nvar);
fake_impact(:,which_shock) = impact;
% Create a fake matrix for the IRFs of the bootstrap
fake_impact_boot = zeros(nvar,nvar,nsimul);
for i_simul = 1:nsimul
      fake_impact_boot(:,which_shock,i_simul) = impact_boot(:,i_simul);
end

%Creating and Printing figures
comment = [which_ID '_' char(varnames(5))];
print_figs = 'no';
%Remove the constant
A = A(:,2:end);
[IRFs, ub1, lb1, ub2, lb2] = genIRFs_VECM(fake_impact,fake_impact_boot,...
      A',permute(A_boot,[2 1 3]),H,sig1, sig2);

% % % With Barsky & Sims-type ID, since you do a abs max, there are two
% % % solutions: gam and -gam. So choose the one that makes sense. I'm doing
% % % that so that the IT shock has positive impact effect on IT.
if IRFs(pos_IT,1,pos_IT) < 0 % if the impact effect on IT is negative
      IRFs(:,:,pos_IT)   = -IRFs(:,:,pos_IT);
      ub1(:,:,pos_IT)     = - ub1(:,:,pos_IT);
      lb1(:,:,pos_IT)     = - lb1(:,:,pos_IT);
      ub2(:,:,pos_IT)     = - ub2(:,:,pos_IT);
      lb2(:,:,pos_IT)     = - lb2(:,:,pos_IT);
end


%Printing/Showing IRFs
h = 40;
% plotIRFs(IRFs,ub,lb,40,which_shocks,shocknames,varnames,which_ID,print_figs)
% plot_single_IRFs(IRFs,ub1,lb1,h,which_shocks,shocknames, varnames, which_ID, print_figs)
use_current_time = 0; % don't save the time
plot_single_IRFs_2CIs(IRFs,ub1,lb1,ub2,lb2,h,which_shock,shocknames, varnames, '_', print_figs, use_current_time)

%Forni&Gambetti Orthogonality Test
do_FG_test = 'no';
switch do_FG_test
      case 'yes'
            filename_PC       = 'Dataset_test_PC';
            sheet_PC          = 'Quarterly';
            range_PC          = 'B2:DC287';
            first_n_PCs       = 10;
            mlags             = 1;
            [pvalue_news_shock, pvalue_IT_shock] = ...
                  Forni_Gambetti_orthogonality_test(filename_PC,...
                  sheet_PC,range_PC,first_n_PCs,A,gam_opt,res,which_shock,mlags)
end

% Build the denominator of variance decomposition
N = null(gam_opt');
D_null = [N gam_opt];
D_null*D_null'; % this is just a check, should be the identity.
impact_vardec = A*D_null; % where A is the chol.
[IRF_vardec, ~, ~, ~, ~] = genIRFs(impact_vardec,0,B,0,H, sig1, sig2);

vardec = gen_vardecomp(IRF_vardec,h,h);
shareIT_on_TFP = vardec(1,end); % "end" b/c we put gam_opt as last.

disp('stopping here')
return
%Saving in Tex format the Variance Decomposition Matrix
fev_matrix = {'News', 'IT', 'Total'};
fev_matrix(2,:) = {num2str(FEV_news), num2str(FEV_IT), num2str(FEV_opt)};
disp('% of FEV of TFP explained:')
fev_matrix

export_FEV_matrix = 'no';
if strcmp(export_FEV_matrix,'yes') ==1
      fev_matrix_out = [FEV_news, FEV_IT, FEV_opt];
      rowLabels = {'Share of TFP FEV explained'};
      columnLabels = {'News', 'IT', 'Total'};
      matrixname   = 'FEVs';
      invoke_matrix_outputting(fev_matrix_out,matrixname,rowLabels,...
            columnLabels,comment);
end

toc
disp(varnames)
disp(datestr(now))







