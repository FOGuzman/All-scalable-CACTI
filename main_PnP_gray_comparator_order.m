clear all;clc
addpath(genpath('./DeSCI-master')); % algorithms
addpath('functions');
addpath('largescale_functions')

vidName = "sticks";

dataFolder = "./dataset_largescale/gray/" + vidName +"/";

list = dir(dataFolder+"*.tiff");
vids = natsort({list.name});

Metrics = 1;
RenderVideo = 1;
RenderFold = "./large_scale_videos";
if ~isfolder(RenderFold);mkdir(RenderFold);end
SaveMask = 0;
OrderType1 = "normal";
OrderType2 = "spiral";


spix = 8;
frames = spix^2*8;
resolution = 256*spix;


if OrderType1 == "normal"       
 orders{1} = reshape([1:spix^2],[spix spix])';
elseif OrderType1 == "spiral"    
    switch spix
        case 4
            orders{1} = [1:4;8:-1:5;9:12;16:-1:13];
        case 8
            orders{1} = [1:8;16:-1:9;17:24;32:-1:25;33:40;48:-1:41;49:56;64:-1:57];
    end
end



if OrderType2 == "normal"       
 orders{2} = reshape([1:spix^2],[spix spix])';
elseif OrderType2 == "spiral"    
    switch spix
        case 4
            orders{2} = [1:4;8:-1:5;9:12;16:-1:13];
        case 8
            orders{2} = [1:8;16:-1:9;17:24;32:-1:25;33:40;48:-1:41;49:56;64:-1:57];
    end
end


DEmethod = "RevSCI";
UPmethod = "2DI";

EDSR_SR = 4;
cod = load('./RevSCI-net-master/train/mask');cod = cod.mask;

RenderName1 = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType1,UPmethod,EDSR_SR);

RenderName2 = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType2,UPmethod,EDSR_SR);


dataRecon{1} = "./large_scale_comparator/gray/" + RenderName1 +"/";
if ~isfolder(dataRecon{1});mkdir(dataRecon{1});end

dataRecon{2} = "./large_scale_comparator/gray/" + RenderName2 +"/";
if ~isfolder(dataRecon{2});mkdir(dataRecon{2});end

fprintf("%s\n%s\n",RenderName1,RenderName2)
%% Load and sampling
for oo = 1:2
cont = 1;
offset = 0;
full_meas = zeros(resolution,resolution);
full_mask = logical([]);
sf = reshape([1:frames],frames/(spix^2),[])';
smallorig = [];
orgcont = 1;

order = VectorOrder(orders{oo},spix);
for k = 1:spix^2

      [vidFrame] = StreamNframes(dataFolder,vids,sf,cont,offset,frames,resolution,spix,"Gray");
      
      
      SubMask = CrateMaskRevSCI(cod,order,k,spix,resolution,frames);
      full_meas = full_meas + sum(vidFrame.*SubMask,3);
      if SaveMask
      full_mask = cat(3,full_mask,SubMask);
      end
      smallorig = cat(3,smallorig,imresize(vidFrame,1/spix));
      if size(smallorig,3)==8
        datae{orgcont} = smallorig;  
        orgcont = orgcont+1;
        smallorig = [];
      end
      
      
      clc
      fprintf("Generating measure data (%i/%i)\n",order(k,1),order(k,2))
      cont = cont+1;
end

%% Recon Revseci
if ~isfolder("./RevSCI-net-master/ExtremeCacti_in")
    mkdir("./RevSCI-net-master/ExtremeCacti_in")
end
if ~isfolder("./RevSCI-net-master/ExtremeCacti_out")
    mkdir("./RevSCI-net-master/ExtremeCacti_out")

end
meas = [];
mask = cod;
orig = [];
rcnt = 1;
for k = 1:spix^2
        SM = full_meas(order(k,1):spix:end,order(k,2):spix:end);
        meas = cat(3,meas,SM);
        SO = datae{k};
        orig = cat(3,orig,squeeze(SO(:,:,:)));
        clc;fprintf('Block (%i,%i) generated\n',order(k,1),order(k,2))
end          
orig = uint8(orig*255);

switch DEmethod
    
    case "RevSCI"


    save("./RevSCI-net-master/ExtremeCacti_in/data_in.mat",'meas','mask','orig')
    save(RenderFold+"/"+RenderName1 + "_full_meas.mat",'full_meas','full_mask')
    clear datae par_meas subMask subMeas vidFrame
    disp("------------- Sending to RevSCI model -----------")
    tic
    system('python ./RevSCI-net-master/recon_extreme_cacti.py');
    disp("------------- Reconstruction done -----------")
    load("./RevSCI-net-master/ExtremeCacti_out/data_out.mat");

    pic_up = RevSCIReshapeGray(pic,frames);
    recon_raw = pic_up;
    
    case "GAP-TV"
     
    disp("Applying GAP-TV...")    
    GAP_TV_propeties_setting;    
    [pic_up] = gapdenoise_cacti(mask,meas*255,orig,[],para);
    recon_raw = pic_up;
    pic_up(pic_up<0) = 0;pic_up(pic_up>1) = 1;
    pic_up = uint8(pic_up*255);
    disp("Done")
    
    case "DeSCI"
        
    disp("Applying DeSCI...")    
    DeSCI_propeties_setting;    
    [pic_up] = gapdenoise_cacti(mask,meas*255,orig,[],para);
    recon_raw = pic_up;
    pic_up(pic_up<0) = 0;pic_up(pic_up>1) = 1;
    pic_up = uint8(pic_up*255);
    disp("Done")    
    
        
end
%%

switch UPmethod
    case "2DI"        
        fprintf('Applying 2D Interpolation');
        for k = 1:size(pic_up,3)
        clc;fprintf('Applying 2D Interpolation for (%i/%i)\n',k,size(pic_up,3));
        dem = pic_up(:,:,k);
        aux = imresize(dem,EDSR_SR);
        fname = sprintf("f_%i_rgb.png",k);
        imwrite(aux,dataRecon{oo}+fname);
        end
        
    case "EDSR"
        EDSR_settings
        fprintf('Applying EDSR for %dx SR\n', EDSR_SR);
        for k = 1:size(pic_up,3)
        clc;fprintf('Applying EDSR for (%i/%i)\n',k,size(pic_up,3));
        fname = sprintf("f_%i_rgb.png",k);
        aux = pic_up(:,:,k);
        imwrite(aux,EDSR_testpath+fname);
        end
        system(execEDSR)
        movefile(EDSR_reconpath+"*.png",dataRecon{oo})

end



end
rtime = toc;
%% Perform video metric and render video.
reconFrame1 = im2double(imread(dataRecon{1}+framesNames1{1}));
GtFrame = imresize(im2double(imread(dataFolder + vids{1+offset}))...
    ,size(reconFrame1,1:2));

figure,
imshow(GtFrame)
[xi,yi] = getpts ;
close all
pixels = round([yi,xi]);

list = dir(dataRecon{1}+"*.png");
framesNames1 = natsort({list.name});
list = dir(dataRecon{2}+"*.png");
framesNames2 = natsort({list.name});

for m = 1:size(pixels,1)
for k = 1:length(framesNames1)
reconFrame1 = im2double(imread(dataRecon{1}+framesNames1{k}));
reconT1(m,k) = reconFrame1(pixels(m,1),pixels(m,2),1);
reconFrame2 = im2double(imread(dataRecon{2}+framesNames2{k}));
reconT2(m,k) = reconFrame2(pixels(m,1),pixels(m,2),1);
GtFrame = imresize(im2double(imread(dataFolder + vids{k+offset}))...
    ,size(reconFrame1,1:2));
GtT(m,k) = GtFrame(pixels(m,1),pixels(m,2),1);
end
end

if size(pixels,1)>1
 reconT1 = mean(reconT1,1);   
 reconT2 = mean(reconT2,1);
 GtT = mean(GtT,1);
end

psnrL1 = psnr(GtT,reconT1);
psnrL2 = psnr(GtT,reconT2);

l1 = sprintf("Normal psnr = %2.2f dB",psnrL1);
l2 = sprintf("Spiral psnr = %2.2f dB",psnrL2);

figure('Color','w','Position',[57 -321 1822 755])
subplot(2,3,1)
imshow(GtFrame)
subplot(2,3,2)
imshow(reconFrame1)
subplot(2,3,3)
imshow(reconFrame2)
subplot(2,3,[4:6])
hold on
plot([1:512],GtT,'k','LineWidth',2)
plot([1:512],reconT1,'r','LineWidth',2)
plot([1:512],reconT2,'b','LineWidth',2)
grid on;xlim([1 512]);box on
legend("Goundtruth",l1,l2,'interpreter','latex','FontSize',14)
xlabel("Frames",'interpreter','latex','FontSize',15)

% if RenderVideo
%   disp("Rendering video")
%   %vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.mp4",'MPEG-4');
%   vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.avi");
%   vid.Quality = 100;
%   vid.FrameRate = 25;
%   open(vid);
%   for k = 1:frames
%     fname = sprintf("f_%i_rgb.png",k);
%     if UPmethod == "EDSR"
%      fname = sprintf("f_%i_rgb_x%i_SR.png",k,EDSR_SR);  
%      dataRecon = EDSR_reconpath;
%     elseif UPmethod == "JDNDMSR"
%          fname = sprintf("f_%i_rgb.png",k);
%          dataRecon = JDNDMSR_reconpath;
%     elseif UPmethod == "JDNDMSR+EDSR"
%           fname = sprintf("f_%i_rgb_x%i_SR.png",k,EDSR_SR);  
%           dataRecon = EDSR_reconpath;
%     end
%     list = dir(dataRecon+"*.png");
%     rframe = natsort({list.name});
% 
%     frame = imread(dataRecon+rframe{k});
%     writeVideo(vid, frame);
%     clc
%     fprintf("Rendering %i-%i\n",k,frames)
%   end
%   close(vid)
% end
%   
% 
% 
% if Metrics
%     fprintf("Calculating PSNR SSIM\n")
%     list = dir(dataRecon+"*.png");
%     framesNames = natsort({list.name});
%     for k = 1:frames     
%         reconFrame = im2double(imread(dataRecon+framesNames{k}));
%         reconFrame = reconFrame(:,:,1);
%         GtFrame = imresize(im2double(imread(dataFolder + vids{k})),size(reconFrame,1:2));
%         v_psnr(k) = psnr(GtFrame,reconFrame);
%         v_ssim(k) = ssim(GtFrame,reconFrame);
%         clc;fprintf('Calculating PSNR SSIM\n Frame %i | rmse = %.2f mean = %.2f | ssim = %.2f mean = %.2f |\n'...
%             ,k,v_psnr(k),mean(v_psnr),v_ssim(k),mean(v_ssim));
%     end
%     save(RenderFold+"/"+RenderName + "_metrics.mat",'v_psnr','v_ssim')
% end



function [vids] = FilterMetric(vids,word)
cont = 1;
for w = 1:length(word)
for k = 1:length(vids)
    if isempty(strfind(vids{k},word{w}))
        D(cont) = k;
        cont = cont+1;
    else
        
    end
end
end
D = unique(D);
vids(D) = [];
end