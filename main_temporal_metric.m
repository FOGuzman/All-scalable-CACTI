clear all;clc;
F = findall(0,'type','figure');delete(F)
addpath(genpath('./tools'));

vidName = "dogo1";
datasetFolder = "./dataset/gray/";
dataFolder = datasetFolder + vidName +"/";
dataRecon = "./large_scale_results/temporal_test/" + vidName +"/";

list = dir(dataFolder+"*.tiff");
frvids = natsort({list.name});


MaskMethod = "MethodDefined";
OrdersT = ["normal","spiral" ,"random", "designed"];
PixelAdjustM  = ["no","pre","post"];
SaveMask = 0;
SelectRegion = 1;
RegionRes = 2;
SwapSensing = 0;
B = 8;
DEmethod = "STT";
UPmethod = "VSR++";
spix = 4;
EDSR_SR = spix;
alpha = B;
frames = spix^2*B;
methodResolution = 256;
resolution = methodResolution*spix;



TO = length(OrdersT);TP = length(PixelAdjustM);
Results = table();
Gcont = 1;
for Os = 1:TO
for Ps = 1:TP 

OrderType = OrdersT(Os);    
PixelAdjust = PixelAdjustM(Ps);


setting_propeties();
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



  vidFrame = StreamNframes(dataFolder,frvids,sf,cont,offset,frames,forder,resolution,spix,"Gray");
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
end

%% Preparing subproblems

[meas,mask,orig] = PrepareSubproblems(full_meas,cod,order,spix,datae);


% point source
% meas = zeros(256,256,spix^2);
% for k = 1:spix^2
%     meas(128,128,k) = 8;
% end

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
%% Perform video temporal metric.


list = dir(dataRecon+"*.png");
framesNames = natsort({list.name});
Nt = length(framesNames);

if SelectRegion
    RefFrame = im2double(imread(dataRecon+framesNames{round(Nt/2)}));
    RefFrame = imresize(RefFrame(:,:,1),[resolution resolution]);
    rff = figure;
    imshow(RefFrame);
    [Px,Py] = ginput(1);Px = round(Px);Py = round(Py);
    clear RefFrame;close(rff)
    SelectRegion = 0;
    
    
    lbar = multiwaitbar(2,[0 0],{'Please wait','Please wait'...
        ,'Please wait','Please wait','Please wait'});
    lbar.figure.Position = [540 -8 600 128];
    for lb=1:2
    lbar.Axeshandle(lb).list.Position(3) = lbar.Axeshandle(lb).list.Position(3)+253;
    end
    lbar.figure.Name= "Calculating Data...";
    drawnow
    
    
end

%Px = 1060;Py = 998;

clc;fprintf("Extracting temporal flow\n");
for k = 1:length(framesNames)      
    reconFrame = im2double(imread(dataRecon+framesNames{k}));
    reconFrame = imresize(reconFrame(:,:,1),[resolution resolution]);
    GtFrame = imresize(im2double(imread(dataFolder + frvids{k+offset})),size(reconFrame,1:2));
    imreg = reconFrame(Py:Py+RegionRes-1,Px:Px+RegionRes-1);
    t_recon(k) = mean(imreg(:));
    imreg      = GtFrame(Py:Py+RegionRes-1,Px:Px+RegionRes-1);
    t_gt(k)    = mean(imreg(:));
end



VideoName = string(vidName);
Resolution = sprintf("%i×%i×%i",resolution,resolution,length(framesNames));
s_param = spix;
alpha_param = alpha;
OrderType;
SwapSensing = logical(SwapSensing);
SubPixelShift = PixelAdjust;
DemultiplexingMethod = DEmethod;
UpscalingMethod = UPmethod;
TimeFlux = t_recon;

auxT = table(VideoName,Resolution,s_param,alpha_param,OrderType,SwapSensing,SubPixelShift,...
    DemultiplexingMethod,UpscalingMethod,TimeFlux);

if Gcont== 1
  Results = auxT;
else
  Results = cat(1,Results,auxT);
end



TxtOs = sprintf("%s - (%i/%i)",OrderType,Os,TO);
TxtPs = sprintf("%s - (%i/%i)",PixelAdjust,Ps,TP);
 multiwaitbar(2,[Os/TO Ps/TP],...
     {TxtOs,TxtPs},lbar);

Gcont = Gcont+1;

end
end

close(lbar.figure)

TimeFlux = t_gt;
VideoName = "Groundtruth";
auxT = table(VideoName,Resolution,s_param,alpha_param,OrderType,SwapSensing,SubPixelShift,...
    DemultiplexingMethod,UpscalingMethod,TimeFlux);

if Gcont== 1
  Results = auxT;
else
  Results = cat(1,Results,auxT);
end


%% Figure 1

time_psnr      = psnr(Results.TimeFlux(end,:),Results.TimeFlux(1,:));
time_psnr(2,:) = psnr(Results.TimeFlux(end,:),Results.TimeFlux(4,:));
time_psnr(3,:) = psnr(Results.TimeFlux(end,:),Results.TimeFlux(7,:));
time_psnr(4,:) = psnr(Results.TimeFlux(end,:),Results.TimeFlux(10,:));

figure('Color','w')
hold on
plot(Results.TimeFlux(end,:),'k','LineWidth',2)
plot(Results.TimeFlux(1,:),'r','LineWidth',2)   
plot(Results.TimeFlux(4,:),'g','LineWidth',2)
plot(Results.TimeFlux(7,:),'b','LineWidth',2)
plot(Results.TimeFlux(10,:),'m','LineWidth',2)
grid on;box on
ylabel("Intensity");xlabel("Frame")

lgl_nm{1} = "Groundtruth";
lgl_nm{2} = sprintf("%s - PSNR = %2.2f dB",Results.OrderType(1,:),time_psnr(1));
lgl_nm{3} = sprintf("%s - PSNR = %2.2f dB",Results.OrderType(4,:),time_psnr(2));
lgl_nm{4} = sprintf("%s - PSNR = %2.2f dB",Results.OrderType(7,:),time_psnr(3));
lgl_nm{5} = sprintf("%s - PSNR = %2.2f dB",Results.OrderType(10,:),time_psnr(4));

legend(lgl_nm)
xlim([1 length(Results.TimeFlux(end,:))])


%% Figure 2
time_psnr      = psnr(Results.TimeFlux(end,:),Results.TimeFlux(1,:));
time_psnr(2,:) = psnr(Results.TimeFlux(end,:),Results.TimeFlux(2,:));
time_psnr(3,:) = psnr(Results.TimeFlux(end,:),Results.TimeFlux(3,:));

figure('Color','w')
hold on
plot(Results.TimeFlux(end,:),'k','LineWidth',2)
plot(Results.TimeFlux(1,:),'r','LineWidth',2)   
plot(Results.TimeFlux(2,:),'g','LineWidth',2)
plot(Results.TimeFlux(3,:),'b','LineWidth',2)

grid on;box on
ylabel("Intensity");xlabel("Frame")

lgl_nm{1} = "Groundtruth";
lgl_nm{2} = sprintf("%s - PSNR = %2.2f dB",Results.SubPixelShift(1,:),time_psnr(1));
lgl_nm{3} = sprintf("%s - PSNR = %2.2f dB",Results.SubPixelShift(2,:),time_psnr(2));
lgl_nm{4} = sprintf("%s - PSNR = %2.2f dB",Results.SubPixelShift(3,:),time_psnr(3));


legend(lgl_nm)
xlim([1 length(Results.TimeFlux(end,:))])