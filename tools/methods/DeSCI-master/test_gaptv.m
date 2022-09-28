%TEST_DESCI Test decompress snapshot compressive imaging (DeSCI) for 
%simulated coded aperture compressive temporal imaging (CACTI) dataset.
% Reference
%   [1] Y. Liu, X. Yuan, J. Suo, D. J. Brady, and Q. Dai, Rank Minimization 
%       for Snapshot Compressive Imaging, IEEE Trans. Pattern Anal. Mach. 
%       Intell. (TPAMI), vol. 41, no. 12, pp. 2990-3006, 2019,
%   [2] X. Yuan, Generalized alternating projection based total variation 
%       minimization for compressive sensing, in Proc. IEEE Int. Conf. 
%       Image Process. (ICIP), pp. 2539-2543, 2016.
% Dataset
%   `kobe` and `traffic` dataset from MMLE-GMM (TIP'15) [3] and GMM-TP
%    (TIP'14) [4], respectively.
%   [3] J. Yang, X. Liao, X. Yuan, P. Llull, D. J. Brady, G. Sapiro, and 
%       L. Carin, Compressive sensing by learning a Gaussian mixture model
%       from measurements, IEEE Trans. Image Process., vol. 24, no. 1, 
%       pp. 106-119, 2015.
%   [4] J. Yang, X. Yuan, X. Liao, P. Llull, G. Sapiro, D. J. Brady, and 
%       L. Carin, Video compressive sensing using Gaussian mixture models,
%       IEEE Trans. Image Process., vol. 23, no. 11, pp. 4863-4878, 2014.
% Contact
%   Xin Yuan, Bell Labs, xyuan@bell-labs.com, initial version Jul 2, 2015.
%   Yang Liu, Tsinghua University, y-liu16@mails.tsinghua.edu.cn, last 
%     update Dec 26, 2018.
%   See also GAPDENOISE_CACTI, GAPDENOISE.
clear; clc;
% close all
% [0] environment configuration
addpath(genpath('./algorithms')); % algorithms
addpath(genpath('./packages')); % packages
addpath(genpath('./utils')); % utilities

datasetdir = './dataset'; % dataset
resultdir  = './results'; % results

% [1] load dataset
para.type   = 'cacti'; % type of dataset, cassi or cacti
para.name   = 'kobe'; % name of dataset
para.number =  32; % number of frames in the dataset

datapath = sprintf('%s/%s%d_%s.mat',datasetdir,para.name,...
    para.number,para.type);

load(datapath); % mask, meas, orig (and para)

para.nframe =   1; % number of coded frames in this test
para.MAXB   = 255;

[nrow,ncol,nmask] = size(mask);
nframe = para.nframe; % number of coded frames in this test
MAXB = para.MAXB;

% [1.2] parameter setting for GAP-TV and GAP-WNNM
para.Mfunc  = @(z) A_xy(z,mask);
para.Mtfunc = @(z) At_xy_nonorm(z,mask);

para.Phisum = sum(mask.^2,3);
para.Phisum(para.Phisum==0) = 1;
% common parameters
para.lambda   =     1; % correction coefficiency
para.acc      =     1; % enable GAP-acceleration
para.flag_iqa = false; % disable image quality assessments in iterations

%% [2.1] GAP-TV, ICIP'16
para.lambda   =    1; % correction coefficiency
para.maxiter  =  100; % maximum iteration
para.acc      =    1; % enable acceleration
para.denoiser = 'tv'; % TV denoising
para.tvweight = 0.07*255/MAXB; % weight for TV denoising
para.tviter   = 5; % number of iteration for TV denoising
  
[vgaptv,psnr_gaptv,ssim_gaptv,tgaptv] = gapdenoise_cacti(mask,meas,orig,[],para);

fprintf('GAP-%s mean PSNR %2.2f dB, mean SSIM %.4f, total time % 4.1f s.\n',...
    upper(para.denoiser),mean(psnr_gaptv),mean(ssim_gaptv),tgaptv);