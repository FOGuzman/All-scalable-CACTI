MAXB   = 255;           % maximum pixel value of the image (8-bit -> 255)

para.nframe = 1; 
para.MAXB   = MAXB;

para.denoiser = 'ffdnet'; % FFDNet denoising
  load(fullfile('models','FFDNet_gray.mat'),'net');
  para.net = vl_simplenn_tidy(net);
  para.useGPU = true;
  if para.useGPU
      para.net = vl_simplenn_move(para.net, 'gpu') ;
  end
  para.ffdnetvnorm_init = true; % use normalized video for the first 10 iterations
  para.ffdnetvnorm = false; % normalize the video before FFDNet video denoising
  para.sigma   =  [50 25 12  6]/MAXB; % noise deviation (to be estimated and adapted)
  para.maxiter =  [10  10 10 20];