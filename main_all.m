clear all;clc;
F = findall(0,'type','figure');delete(F)
addpath(genpath("tools"))

datasetFolder = "./dataset/gray/";
MetricFold = "./large_scale_metrics_results/comparing_all/";

% append sesion in xls file
xlsFold = "./figures/table/";
xlsSession = date;


if ~isfolder(MetricFold);mkdir(MetricFold);end
list = dir("dataset/gray");
Video_list = natsort({list.name});
Video_list = Video_list(3:3:end);
dataRecon = "./large_scale_results/gray/" + "Metric_aux" + "/";




UpMs = ["TC"];
DeMs = ["RevSCI","SCI3D","STT"];
alphas = [8];
SpixS = [8];

MaskMethod = "MethodDefined";
SaveMask = 0;
OrderType = "spiral";
StreamMode = "sequential";
SwapSensing = 0;
B = 8;

PixelAdjust = "post";

lbar = multiwaitbar(5,[0 0 0 0 0],{'Please wait','Please wait'...
    ,'Please wait','Please wait','Please wait'});
lbar.figure.Position = [540 -8 650 328];
for lb=1:5
lbar.Axeshandle(lb).list.Position(3) = lbar.Axeshandle(lb).list.Position(3)+253;
end
lbar.figure.Name= "Calculating Data...";
Ta = length(alphas);Td = length(DeMs); Tu = length(UpMs); Tv = length(Video_list);
Ts = length(SpixS);
drawnow
Results = table();
xslcont = 1;
for Ss = 1:Ts
for as = 1:Ta
for ds = 1:Td
for us = 1:Tu


spix = SpixS(Ss);
DEmethod = DeMs(ds);
UPmethod = UpMs(us);
EDSR_SR = spix;
alpha = alphas(as);
frames = spix^2*B;
methodResolution = 256;
resolution = methodResolution*spix;

    
for vs = 1:Tv
    
setting_propeties_loop();
%% Load and sampling

if isfile(MetricFold+RenderName + "_metrics.mat");break;end
cont = 1;
offset = 0;
full_meas = zeros(resolution,resolution);
full_mask = logical([]);
sf = reshape([1:frames],frames/(spix^2),[])';
smallorig = [];
orgcont = 1;
order = VectorOrder(order,spix);
  for k = 1:spix^2



  [vidFrame] = StreamNframes(dataFolder,frvids,sf,cont,offset,frames,forder,resolution,spix,"Gray");
  SubMask  = ExtractSubmasks(cod,order,k,spix,resolution,frames);
  full_meas = full_meas + sum(vidFrame.*SubMask,3);
  if SaveMask
    full_mask = cat(3,full_mask,SubMask);
  end
  smallorig = cat(3,smallorig,imresize(vidFrame,1/spix));
  if size(smallorig,3)==B
    datae{orgcont} = smallorig;  
    orgcont = orgcont+1;
    smallorig = [];
  end
      
      
      clc
      fprintf("Generating measure data (%i/%i)\n",order(k,1),order(k,2))
      cont = cont+1;
  end %Processing video

%% Preparing subproblems
[meas,mask,orig] = PrepareSubproblems(full_meas,cod,order,spix,datae);

tic
%% Demultiplexing
demultiplexing_methods
dtime = toc;

% pre metrics
    for k = 1:size(orig,3)
    DE_psnr_v(k) = psnr(orig(:,:,k)/255,im2double(recon_raw(:,:,k)));
    DE_ssim_v(k) = ssim(orig(:,:,k)/255,im2double(recon_raw(:,:,k)));
    end
%% Adjust subpixel pre Upscaling
if PixelAdjust == "pre";pic_up = FourierShift(recon_raw,order,spix,B);end

%% Upscaling

tic
upscaling_methods
utime = toc;


%% Antialising filtering
    if UPmethod ~= "TC" && alpha < B
     auxRecon = "./large_scale_results/gray/aux/"; 
     delete(auxRecon+"*.png")

     if ~isfolder(auxRecon);mkdir(auxRecon);end
      list = dir(dataRecon+"*.png");
        rframe = natsort({list.name});  
     for k = 1:max(forder)   
      fsls = find(forder==k);
        frame =zeros(resolution,resolution);
         for s = 1:length(fsls)
             aux = double(imread(dataRecon+rframe{fsls(s)}));
          frame = frame+aux;
         end
        frame =uint8(frame/length(fsls));

      fname = sprintf("f_%i_gray.png",k);
      imwrite(frame,auxRecon+fname);  

     end

    delete(dataRecon+"*.png") 
    movefile(auxRecon+"*.png",dataRecon)   

    end
rtime = toc;
%% Perform video metric and render video.


fprintf("Calculating PSNR SSIM\n")
list = dir(dataRecon+"*.png");
framesNames = natsort({list.name});
Up_psnr_v = [];
Up_ssim_v = [];
for k = 1:length(framesNames)  
    
    
    reconFrame = im2double(imread(dataRecon+framesNames{k}));
    reconFrame = imresize(reconFrame(:,:,1),[resolution resolution]);
    GtFrame = imresize(im2double(imread(dataFolder + frvids{k+offset})),size(reconFrame,1:2));
    if PixelAdjust == "post"   
    Up_psnr_v(k) = psnr(GtFrame(spix:end-spix,spix:end-spix)...
                    ,reconFrame(spix:end-spix,spix:end-spix));
    Up_ssim_v(k) = ssim(GtFrame(spix:end-spix,spix:end-spix)...
                    ,reconFrame(spix:end-spix,spix:end-spix));
    else
    Up_psnr_v(k) = psnr(GtFrame,reconFrame);
    Up_ssim_v(k) = ssim(GtFrame,reconFrame);    
    end   
    clc;fprintf('Calculating PSNR SSIM\n Frame %i | psnr = %.2f mean = %.2f | ssim = %.4f mean = %.4f |\n'...
        ,k,Up_psnr_v(k),mean(Up_psnr_v),Up_ssim_v(k),mean(Up_ssim_v));
end

Up_psnr_v(isinf(Up_psnr_v)) = [];
Up_ssim_v(isinf(Up_psnr_v)) = [];

DE_psnr_mean = mean(DE_psnr_v);
DE_ssim_mean = mean(DE_ssim_v);
DE_psnr_std = std(DE_psnr_v);
DE_ssim_std = std(DE_ssim_v);
Up_psnr_mean = mean(Up_psnr_v);
Up_ssim_mean = mean(Up_ssim_v);
Up_psnr_std = std(Up_psnr_v);
Up_ssim_std = std(Up_ssim_v);




%% Data table
VideoName = string(vidName);
Resolution = sprintf("%i×%i×%i",resolution,resolution,length(framesNames));
s_param = spix;
alpha_param = alpha;
OrderType;
SwapSensing = logical(SwapSensing);
DemultiplexingMethod = DeMs(ds);
UpscalingMethod = UpMs(us);
DemultiplexingPSNR = DE_psnr_mean;
DemultiplexingSSIM = DE_ssim_mean;
UpscalingPSNR      = Up_psnr_mean;
UpscalingSSIM      = Up_ssim_mean;
DemultiplexingTime = dtime;
UpscalingTime = utime;
TotalTime = dtime+utime;
auxT = table(VideoName,Resolution,s_param,alpha_param,OrderType,SwapSensing,...
    DemultiplexingMethod,DemultiplexingPSNR,DemultiplexingSSIM,DemultiplexingTime,...
    UpscalingMethod,UpscalingPSNR,UpscalingSSIM,UpscalingTime,TotalTime);

 if vs== 1
  Results = auxT;
 else
  Results = cat(1,Results,auxT);
 end
 
 
TxtAs = sprintf("alpha = %i - (%i/%i)",alpha,as,Ta);
TxtSs = sprintf("s = %i - (%i/%i)",spix,Ss,Ts);
TxtDs = sprintf("%s - (%i/%i)",DEmethod,ds,Td);
TxtUs = sprintf("%s - (%i/%i)",UPmethod,us,Tu);
TxtVs = sprintf("%s - (%i/%i)",vidName,vs,Tv);
 multiwaitbar(5,[Ss/Ts as/Ta ds/Td us/Tu vs/Tv],...
     {TxtSs,TxtAs,TxtDs,TxtUs,TxtVs},lbar);   
  




end

if ~isfile(MetricFold+RenderName + "_metrics.mat");

VideoName = "Total Mean";
Resolution = sprintf("%i×%i×%i",resolution,resolution,length(framesNames));
s_param = spix;
alpha_param = alpha;
OrderType;
SwapSensing = logical(SwapSensing);
DemultiplexingMethod = DeMs(ds);
DemultiplexingPSNR = mean(Results{:,8});
DemultiplexingSSIM = mean(Results{:,9});
DemultiplexingTime = mean(Results{:,10});
UpscalingMethod    = UpMs(us);
UpscalingPSNR      = mean(Results{:,12});
UpscalingSSIM      = mean(Results{:,13});
UpscalingTime      = mean(Results{:,14});
TotalTime          = mean(Results{:,15});

auxT = table(VideoName,Resolution,s_param,alpha_param,OrderType,SwapSensing,...
    DemultiplexingMethod,DemultiplexingPSNR,DemultiplexingSSIM,DemultiplexingTime,...
    UpscalingMethod,UpscalingPSNR,UpscalingSSIM,UpscalingTime,TotalTime);
Results = cat(1,Results,auxT);


VideoName = "Total Std";
Resolution = sprintf("%i×%i×%i",resolution,resolution,length(framesNames));
s_param = spix;
alpha_param = alpha;
OrderType;
SwapSensing = logical(SwapSensing);
DemultiplexingMethod = DeMs(ds);
DemultiplexingPSNR = std(Results{:,8});
DemultiplexingSSIM = std(Results{:,9});
DemultiplexingTime = std(Results{:,10});
UpscalingMethod    = UpMs(us);
UpscalingPSNR      = std(Results{:,12});
UpscalingSSIM      = std(Results{:,13});
UpscalingTime      = std(Results{:,14});
TotalTime          = std(Results{:,15});

auxT = table(VideoName,Resolution,s_param,alpha_param,OrderType,SwapSensing,...
    DemultiplexingMethod,DemultiplexingPSNR,DemultiplexingSSIM,DemultiplexingTime,...
    UpscalingMethod,UpscalingPSNR,UpscalingSSIM,UpscalingTime,TotalTime);
Results = cat(1,Results,auxT);

save(MetricFold+RenderName + "_metrics.mat",'Results')


if ~isfile(xlsFold+sprintf("session_%s.xlsx",xlsSession))
    mkdir(xlsFold)
    writetable(Results,xlsFold+sprintf("session_%s.xlsx",xlsSession),'Sheet',xslcont);
else
    writetable(Results,xlsFold+sprintf("session_%s.xlsx",xlsSession),'Sheet',xslcont,'WriteMode','append');
end

end

xslcont = xslcont+1;
end
end
end
end