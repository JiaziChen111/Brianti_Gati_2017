% MODEL_LINEAR - Linearized version of the simple RBC model example from 
% EC860.
%
% usage:
%
% [fy, fx, fyp, fxp] = model(param)
%
% where
%
% param = a parameters object, created in parmeters.m
%
% NOTES: This program, which generates the model matrices in cannonical form,
%        requires the MATLAB symbolic toolbox! The algorithm used to solve 
%        the model, however, is numerical and requires no m-files
%        beyond those that appear in this directory.
%
% Code by Ryan Chahrour, Boston College, 2014
 
% This is OULTON 2010 WITH GROWTH STATIONARIZED WITH EXOG STUFF

function [fyn, fxn, fypn, fxpn] = model_exog_stat(param)

%Steady State
[ss, param] = model_exog_stat_ss(param);

%Declare parameters
bet      = param.bet;  %Never call anything beta...it's a matlab function
a        = param.a; % share of standard capital
b        = param.b; % share of IT capital
biggami     = param.biggami; % growth rate of equipment productivity
biggamc     = param.biggamc;    % growth rate of neutral technology
di       = param.di; % depreciation rate of capital IT
dc       = param.dc; % depreciation rate of capital standard
chi      = param.chi; % preference parameter.

%Declare Needed Symbols
syms KC KI KC1 KC2 KI1 KI2 % 6 vars
syms KC_p KI_p KC1_p KC2_p KI1_p KI2_p 
syms BIGGAMC BIGGAMI % 2 vars
syms BIGGAMC_p BIGGAMI_p 
syms YC YI C IC IT W RC RI H H1 H2 % 11 vars
syms YC_p YI_p C_p IC_p IT_p W_p RC_p RI_p H_p H1_p H2_p  
syms P P_p % 1 var  % -> 20 vars
syms CL CL_p KIL KIL_p KCL KCL_p YCL YCL_p YIL YIL_p HL HL_p PL PL_p KC2L KC2L_p KI2L KI2L_p
syms GAMC GAMC_p GAMKI GAMKI_p GAMKC GAMKC_p GAMYC GAMYC_p GAMYI GAMYI_p GAMH GAMH_p GAMP GAMP_p GAMKC2 GAMKC2_p GAMKI2 GAMKI2_p
syms BIGGAMCL BIGGAMCL_p BIGGAMIL BIGGAMIL_p

%Declare X and Y vectors
% KC KI BIGGAMC BIGGAMI
X  = [KC KI BIGGAMC BIGGAMI ...
    CL KIL BIGGAMCL BIGGAMIL YCL YIL HL PL KC2L KI2L]; % vector of state variables  
XP = [KC_p KI_p BIGGAMC_p BIGGAMI_p ...
    CL_p KIL_p BIGGAMCL_p BIGGAMIL_p YCL_p YIL_p HL_p PL_p KC2L_p KI2L_p]; % p signifies t+1 

% YC YI C IC IT W RC RI H H1 H2 KC1 KC2 KI1 KI2 P
Y  = [YC YI C IC IT W RC RI H H1 H2 KC1 KC2 KI1 KI2 P ...
    GAMC GAMKI GAMYC GAMYI GAMH GAMP GAMKC2 GAMKI2]; % vector of controls
YP = [YC_p YI_p C_p IC_p IT_p W_p RC_p RI_p H_p H1_p H2_p KC1_p KC2_p KI1_p KI2_p P_p ...
    GAMC_p GAMKI_p GAMYC_p GAMYI_p GAMH_p GAMP_p GAMKC2_p GAMKI2_p] ;

%Make index variables for future use
make_index([Y,X])

% Model Equations (my notes p. 287):
f(1)    = -YC + BIGGAMC*H1^(1-a-b)*KC1^(a)*KI1^(b); 
f(end+1)= -YI + BIGGAMI*H2^(1-a-b)*KC2^(a)*KI2^(b); %
f(end+1)= -KC + KC1 + KC2; 
f(end+1)= -KI + KI1 + KI2; 
f(end+1)= -H + H1 + H2; 
f(end+1)= -KC_p*(BIGGAMC^((1-b)/(1-a-b)) *BIGGAMI^((b)/(1-a-b))) + (1-dc)*KC + IC;
f(end+1)= -KI_p*(BIGGAMC^((a)/(1-a-b)) *BIGGAMI^((1-a)/(1-a-b))) + (1-di)*KI + IT; 
f(end+1)= -YC + C + IC;
f(end+1)= -YI + IT;
f(end+1)= -W/C + chi;
f(end+1)= -1 + bet*C/C_p* ((1/(BIGGAMC))^((1-b)/(1-a-b)) *(1/(BIGGAMI))^((b)/(1-a-b)))  *(RC_p + 1-dc);
f(end+1)= -1 + bet*C/C_p* ((1/(BIGGAMC))^((1-b)/(1-a-b)) *(1/(BIGGAMI))^((b)/(1-a-b)))* BIGGAMC/BIGGAMI *(RI_p/P_p + 1-di); %
f(end+1)= -W + (1-a-b)*BIGGAMC*H1^(-a-b)*KC1^(a)*KI1^(b); 
f(end+1)= -RC + a*BIGGAMC*H1^(1-a-b)*KC1^(a-1)*KI1^(b);
f(end+1)= -RI + b*BIGGAMC*H1^(1-a-b)*KC1^(a)*KI1^(b-1);
f(end+1)= -W + (1-a-b)*BIGGAMI*H2^(-a-b)*KC2^(a)*KI2^(b)*P; 
f(end+1)= -RC + a*BIGGAMI*H2^(1-a-b)*KC2^(a-1)*KI2^(b)*P; 
f(end+1)= -RI + b*BIGGAMI*H2^(1-a-b)*KC2^(a)*KI2^(b-1)*P; 
f(end+1)= log(BIGGAMC_p/biggamc) - .8*log(BIGGAMC/biggamc); %taken directly from Ryan's example code.
f(end+1)= log(BIGGAMI_p/biggami) - .8*log(BIGGAMI/biggami); %taken directly from Ryan's example code.
% Approach for growth rates:
f(end+1)= BIGGAMCL_p - BIGGAMC;
f(end+1)= BIGGAMIL_p - BIGGAMI;
f(end+1)= CL_p - C;
f(end+1)= KIL_p - KI;
f(end+1)= YCL_p - YC;
f(end+1)= YIL_p - YI;
f(end+1)= HL_p - H;
f(end+1)= PL_p -P;
f(end+1)= KC2L_p - KC2;
f(end+1)= KI2L_p - KI2;
f(end+1)= GAMC - C/CL*(BIGGAMCL^((1-b)/(1-a-b)) *BIGGAMIL^((b)/(1-a-b)));
f(end+1)= GAMKI - KI/KIL*(BIGGAMCL^((a)/(1-a-b)) *BIGGAMIL^((1-a)/(1-a-b)));
f(end+1) = GAMYC - YC/YCL*(BIGGAMCL^((1-b)/(1-a-b)) *BIGGAMIL^((b)/(1-a-b)));
f(end+1) = GAMYI - YI/YIL*(BIGGAMCL^((a)/(1-a-b)) *BIGGAMIL^((1-a)/(1-a-b)));
f(end+1) = GAMH - H/HL;
f(end+1) = GAMP - P/PL*BIGGAMCL/BIGGAMIL;
f(end+1) = GAMKC2 - KC2/KC2L*(BIGGAMCL^((1-b)/(1-a-b)) *BIGGAMIL^((b)/(1-a-b)));
f(end+1) = GAMKI2 - KI2/KI2L*(BIGGAMCL^((a)/(1-a-b)) *BIGGAMIL^((1-a)/(1-a-b)));


%Check Computation of Steady-State Numerically
fnum = double(subs(f, [Y X YP XP], [ss, ss]));
disp('Checking steady-state equations:')
disp(fnum);

%Log-linear approx
log_var = [];
f = subs(f, log_var, exp(log_var)); 
   
%Differentiate
fx  = jacobian(f,X);
fy  = jacobian(f,Y);
fxp = jacobian(f,XP); 
fyp = jacobian(f,YP);

%Plug back into levels
fx =  subs(fx , log_var, log(log_var));
fy =  subs(fy , log_var, log(log_var));
fxp = subs(fxp, log_var, log(log_var));
fyp = subs(fyp, log_var, log(log_var));

%Compute numerical values
fxn =  double(subs(fx , [Y X YP XP], [ss, ss]));
fyn =  double(subs(fy , [Y X YP XP], [ss, ss]));
fxpn = double(subs(fxp, [Y X YP XP], [ss, ss]));
fypn = double(subs(fyp, [Y X YP XP], [ss, ss]));
