function [IRFs, ub1, lb1, ub2, lb2] ...
        = genIRFs_VECM(B_IRF,B_irf_boot,A_gam,A_gam_boot,H,sig1, sig2)
% Generate IRFs and bootstrapped IRF confidence intervals for ALL shocks
% H = IR horizon for the generation of IRFs (to be used in variance decomposition)
% sig1 = CI significance level (enter as 0.9 for example)
% sig2 = a 2nd CI significance level (enter as 0.95 for example)
% B_irf is the impact matrix and it coming from the LL optimization (nvar,nvar)
% A_gam comes from the redu-rank regression. See Lutkepohl (2005) beginning ...
% of section 2.2. (nvar,nvar*nlags)
% X_Boot follows from the bootstrap
% Can choose not to do bootstrapping by setting A_boot to 0.

nvar = size(B_IRF,1);
nlag = (size(A_gam,1))/nvar;
nshocks = nvar; 
nsimul = size(B_irf_boot,3);
perc_up1 = ceil(nsimul*sig1); % the upper percentile of bootstrapped responses for CI
perc_low1 = floor(nsimul*(1-sig1)); % the lower percentile of bootstrapped responses for CI
perc_up2 = ceil(nsimul*sig2); % same for 2nd CI
perc_low2 = floor(nsimul*(1-sig2)); % same for 2nd CI

% Remove constant - No constant for now!
% A_gam = A_gam(2:end,:);
% A_gam_boot = A_gam_boot(2:end,:,:);

% Preallocate IRs
IRFs = zeros(nvar,H,nshocks);
IRFs_boot = zeros(nvar,H,nshocks,nsimul);
IRFs_boot_sorted = zeros(nvar,H,nshocks,nsimul);
ub1 = zeros(nvar,H,nshocks);
lb1 = zeros(nvar,H,nshocks);
ub2 = zeros(nvar,H,nshocks);
lb2 = zeros(nvar,H,nshocks);

for i_shock=1:nshocks
    shocks = zeros(nvar,1);
    shocks(i_shock,1) = 1;
    
    % Initialize:
    IRFs(:,1,i_shock) = B_IRF*shocks; %Impact
    F = [IRFs(:,1,i_shock)' zeros(1,(nlag-1)*nvar)];
    % Generate IRFs
    for k=2:H
        IRFs(:,k,i_shock) = F*A_gam;
        F = [IRFs(:,k,i_shock)' F(1:end-nvar)];
    end
    
    if sum(sum(B_irf_boot)) == 0
        % don't do bootstrapping
    else
        % Redo for bootstrapped samples: Here we need an extra loop over nsimul
        for i_sim=1:nsimul
            %Initialize:
            IRFs_boot(:,1,i_shock,i_sim) = B_irf_boot(:,:,i_sim)*shocks;
            F_boot = [IRFs_boot(:,1,i_shock,i_sim)' zeros(1,(nlag-1)*nvar)];
            %Generate IRFs
            for k=2:H
                IRFs_boot(:,k,i_shock,i_sim) = F_boot*A_gam_boot(:,:,i_sim);
                F_boot = [IRFs_boot(:,k,i_shock,i_sim)' F_boot(1:end-nvar)];
            end
            % If bootstraps go the wrong way, flip them
            if i_shock == 3 % only do for IT shock since news never flips
                
                which_flip_test = 'old';
                switch which_flip_test
                    case 'old'
                        % thinks of the flip as being a mirror around the 0-line
                        if sum(sum(abs(IRFs_boot(:,:,i_shock,i_sim) - IRFs(:,:,i_shock)))) ...
                                >= sum(sum(abs(IRFs_boot(:,:,i_shock,i_sim) + IRFs(:,:,i_shock))))
                            IRFs_boot(:,:,i_shock,i_sim) = - IRFs_boot(:,:,i_shock,i_sim);
                        else
                            IRFs_boot(:,:,i_shock,i_sim) = IRFs_boot(:,:,i_shock,i_sim);
                        end
                    case 'alternative'
                        % alternative test for 'going the wrong way' for IT:
                        % If the response of TFP to IT is negative at some far
                        % horizon, the flip all the responses to the IT shock
                        far_out = 40;
                        if IRFs_boot(1,far_out, i_sim) < 0
                            IRFs_boot(:,:,i_shock,i_sim) = - IRFs_boot(:,:,i_shock,i_sim);
                        end
                end
            end
        end
        
        % Sort bootstrap IRFs and set lower and upper bounds
        for i_shocks = 1:nshocks
            IRFs_boot_sorted(:,:,i_shocks,:) = sort(IRFs_boot(:,:,i_shocks,:),4);
            ub1(:,:,i_shocks) = IRFs_boot_sorted(:,:,i_shocks,perc_up1);
            lb1(:,:,i_shocks) = IRFs_boot_sorted(:,:,i_shocks,perc_low1);
            ub2(:,:,i_shocks) = IRFs_boot_sorted(:,:,i_shocks,perc_up2);
            lb2(:,:,i_shocks) = IRFs_boot_sorted(:,:,i_shocks,perc_low2);
        end
    end
%         %Normalization
%         ub1(:,:,i_shock)   = ub1(:,:,i_shock)/IRFs(i_shock,1,i_shock);
%         lb1(:,:,i_shock)   = lb1(:,:,i_shock)/IRFs(i_shock,1,i_shock);
%         ub2(:,:,i_shock)   = ub2(:,:,i_shock)/IRFs(i_shock,1,i_shock);
%         lb2(:,:,i_shock)   = lb2(:,:,i_shock)/IRFs(i_shock,1,i_shock);
%         IRFs(:,:,i_shock) = IRFs(:,:,i_shock)/IRFs(i_shock,1,i_shock); % so that each IRF is in terms of the impact change for that shock of the shocked variable
    
end