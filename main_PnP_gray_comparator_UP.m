clear all;clc;
addpath(genpath("tools"))

datasetFolder = "./dataset/gray/";
MetricFold = "./large_scale_metrics_results/comparing_all/";
danaName = "";



if ~isfolder(MetricFold);mkdir(MetricFold);end
list = dir("dataset/gray");
Video_list = natsort({list.name});
Video_list = Video_list(3:end);

dataRecon = "./large_scale_results/gray/" + "Metric_aux2" + "/";
dataReconCmp = "./large_scale_results/gray/" + "ComparatorsFrame" + "/";
if ~isfolder(dataReconCmp);mkdir(dataReconCmp);end


UpMs = ["VSR++"];
DEmethod = "STT";
alpha = 8;
spix = 8;
MaskMethod = "MethodDefined";
SaveMask = 0;
OrderType = "spiral";
StreamMode = "sequential";
SwapSensing = 0;
B = 8;

PixelAdjust = "post";

EDSR_SR = spix;
frames = spix^2*B;
methodResolution = 256;
resolution = methodResolution*spix;

vs = 25; %select video%
BestFrame = 256;

Tu = length(UpMs); Tv = length(Video_list);



for us = 1:Tu


UPmethod = UpMs(us);

    

    
setting_propeties_loop();
%% Load and sampling

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

%% Demultiplexing
demultiplexing_methods

%% Adjust subpixel pre Upscaling
if PixelAdjust == "pre";pic_up = FourierShift(recon_raw,order,spix,B);end

%% Upscaling

upscaling_methods


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
reconFrame = im2double(imread(dataRecon+framesNames{BestFrame}));
reconFrame = imresize(reconFrame(:,:,1),[resolution resolution]);
GtFrame = imresize(im2double(imread(dataFolder + frvids{BestFrame+offset})),size(reconFrame,1:2));
imwrite(reconFrame,dataReconCmp+vidName+"_"+BestFrame+"_"+UPmethod+".tiff")
imwrite(GtFrame,dataReconCmp+vidName+"_"+BestFrame+"_"+"GT"+".tiff")

clc;
fprintf("Frames Done (%i,%i)\n",us,Tu)
end


%% Figure
save_path = "./figures/";
fig_name = "ComparatorUP.pdf";

list = dir(dataReconCmp+"*.tiff");
fnames = natsort({list.name});

GT = imread(dataReconCmp+fnames{4});
f2DI = imread(dataReconCmp+fnames{1});
f3DI = imread(dataReconCmp+fnames{2});
fEDSR = imread(dataReconCmp+fnames{3});
fVSR = imread(dataReconCmp+fnames{6});
fVSRpp = imread(dataReconCmp+fnames{5});

rs = 360;
roi1 = [1536 390];
roi2 = [1000 270];
roi3 = [1300 730];

fig = figure('Color','w','Position',[560 190 1324 665]);

ha = tight_subplot(3,6,[.001 .001],[.001 .001],[.001 .001]);

axes(ha(1))
imshow(GT(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))
axes(ha(2))
imshow(f2DI(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))
axes(ha(3))
imshow(f3DI(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))
axes(ha(4))
imshow(fEDSR(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))
axes(ha(5))
imshow(fVSR(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))
axes(ha(6))
imshow(fVSRpp(roi1(1):roi1(1)+rs-1,roi1(2):roi1(2)+rs-1))

axes(ha(7))
imshow(GT(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))
axes(ha(8))
imshow(f2DI(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))
axes(ha(9))
imshow(f3DI(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))
axes(ha(10))
imshow(fEDSR(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))
axes(ha(11))
imshow(fVSR(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))
axes(ha(12))
imshow(fVSRpp(roi2(1):roi2(1)+rs-1,roi2(2):roi2(2)+rs-1))

axes(ha(13))
imshow(GT(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))
axes(ha(14))
imshow(f2DI(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))
axes(ha(15))
imshow(f3DI(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))
axes(ha(16))
imshow(fEDSR(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))
axes(ha(17))
imshow(fVSR(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))
axes(ha(18))
imshow(fVSRpp(roi3(1):roi3(1)+rs-1,roi3(2):roi3(2)+rs-1))

exportgraphics(fig,save_path+fig_name);