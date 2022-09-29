para.number =  frames/spix^2; % number of frames in the dataset

para.nframe =   size(meas,3); % number of coded frames in this test
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

%% [2.2] DeSCI, TPAMI'18
tic
para.acc = 1; % enable acceleration
para.denoiser = 'wnnm'; % WNNM denoising
  para.wnnm_int = true; % enable GAP-WNNM integrated
    para.blockmatch_period = 20; % period of block matching
  para.sigma   = [100 50 25 12  6]/MAXB; % noise deviation (to be estimated and adapted)
  para.vrange  = 1; % value range
  para.maxiter = [ 60 60 60 60 60];
  para.iternum = 1; % iteration number in WNNM
  para.enparfor = true; % enable parfor for multi-CPU acceleration
  if para.enparfor % if parfor is enabled, start parpool in advance
      mycluster = parcluster('local');
      delete(gcp('nocreate')); % delete current parpool
      poolobj = parpool(mycluster,min(nmask,mycluster.NumWorkers));
  end