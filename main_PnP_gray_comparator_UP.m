clear all;clc
addpath(genpath('./DeSCI-master')); % algorithms
addpath('functions');
addpath('largescale_functions')

vidName = "blade_runner";

dataFolder = "./dataset_largescale/gray/" + vidName +"/";

list = dir(dataFolder+"*.tiff");
vids = natsort({list.name});

Metrics = 1;
RenderVideo = 1;
RenderFold = "./large_scale_videos";
if ~isfolder(RenderFold);mkdir(RenderFold);end
SaveMask = 0;
OrderType = "normal";



spix = 8;
frames = spix^2*8;
resolution = 256*spix;


if OrderType == "normal"       
 order = reshape([1:spix^2],[spix spix])';
elseif OrderType == "spiral"    
    switch spix
        case 2
            order = [1,2;4,3];        
        case 4
            order = [1:4;8:-1:5;9:12;16:-1:13];
        case 8
            order = [1:8;16:-1:9;17:24;32:-1:25;33:40;48:-1:41;49:56;64:-1:57];
    end
end



DEmethod = "RevSCI";
UPmethod1 = "2DI";
UPmethod2 = "EDSR";
UPmethod3 = "VSR";

EDSR_SR = 4;
if DEmethod == "RevSCI"
cod = load('./RevSCI-net-master/train/mask');cod = cod.mask;
end

if DEmethod == "SCI3D"
cod = load('./SCI3D-main/simulation_dataset/traffic.mat');cod = cod.mask;
end

RenderName1 = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType,UPmethod1,EDSR_SR);

RenderName2 = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType,UPmethod2,EDSR_SR);

RenderName3 = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType,UPmethod3,EDSR_SR);


dataRecon1 = "./large_scale_comparator/gray/" + RenderName1 +"/";
if ~isfolder(dataRecon1);mkdir(dataRecon1);end

dataRecon2 = "./large_scale_comparator/gray/" + RenderName2 +"/";
if ~isfolder(dataRecon2);mkdir(dataRecon2);end

dataRecon3 = "./large_scale_comparator/gray/" + RenderName3 +"/";
if ~isfolder(dataRecon3);mkdir(dataRecon3);end





fprintf("%s\n%s\n%s\n",RenderName1,RenderName2,RenderName3)
%% Load and sampling
cont = 1;
offset = 1300;
full_meas = zeros(resolution,resolution);
full_mask = logical([]);
sf = reshape([1:frames],frames/(spix^2),[])';
smallorig = [];
orgcont = 1;
order = VectorOrder(order,spix);
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

switch UPmethod1
    case "2DI"        
        fprintf('Applying 2D Interpolation');
        for k = 1:size(pic_up,3)
        clc;fprintf('Applying 2D Interpolation for (%i/%i)\n',k,size(pic_up,3));
        dem = pic_up(:,:,k);
        aux = imresize(dem,EDSR_SR);
        fname = sprintf("f_%i_rgb.png",k);
        imwrite(aux,dataRecon1+fname);
        end
        

end

switch UPmethod2
        
    case "EDSR"
        EDSR_settings
        delete(EDSR_testpath+"*.png")
        delete(EDSR_reconpath+"*.png")
        fprintf('Applying EDSR for %dx SR\n', EDSR_SR);
        for k = 1:size(pic_up,3)
        clc;fprintf('Applying EDSR for (%i/%i)\n',k,size(pic_up,3));
        fname = sprintf("f_%i_rgb.png",k);
        aux = pic_up(:,:,k);
        imwrite(aux,EDSR_testpath+fname);
        end
        system(execEDSR)
        movefile(EDSR_reconpath+"*.png",dataRecon2)

end


switch UPmethod3
        
     case "VSR"
        VSR_settings
        delete(VSR_testpath+"*.png")
        delete(VSR_reconpath+"*.png")
        fprintf('Applying VSR for %dx SR\n', EDSR_SR);
        if ~isfolder(VSR_testpath);mkdir(VSR_testpath);end
        for k = 1:size(pic_up,3)
        clc;fprintf('Applying EDSR for (%i/%i)\n',k,size(pic_up,3));
        fname = sprintf("f_%i_rgb.png",k);
        aux = pic_up(:,:,k);
        imwrite(aux,VSR_testpath+fname);
        end
        
        system(execVSR)
        movefile(VSR_reconpath+"*.png",dataRecon3)    

end

rtime = toc;
%% Perform video metric and render video.

sframe = 300;
zoomc = [1200 1100 256];
chr = [zoomc(1),zoomc(1)+zoomc(3);zoomc(2),zoomc(2)+zoomc(3)];

list = dir(dataRecon1+"*.png");
framesNames1 = natsort({list.name});
list = dir(dataRecon2+"*.png");
framesNames2 = natsort({list.name});
list = dir(dataRecon3+"*.png");
framesNames3 = natsort({list.name});

reconFrame1 = im2double(imread(dataRecon1+framesNames1{sframe}));
reconFrame1 = reconFrame1(:,:,1);
reconFrame2 = im2double(imread(dataRecon2+framesNames2{sframe}));
reconFrame2 = reconFrame2(:,:,1);
reconFrame3 = im2double(imread(dataRecon3+framesNames3{sframe}));
reconFrame3 = reconFrame3(:,:,1);
GtFrame = imresize(im2double(imread(dataFolder + vids{sframe+offset}))...
    ,size(reconFrame1,1:2));

if size(reconFrame1,1)~= resolution
    reconFrame1 = imresize(reconFrame1,[resolution resolution]);
end

if size(reconFrame2,1)~= resolution
    reconFrame2 = imresize(reconFrame2,[resolution resolution]);
end

if size(reconFrame3,1)~= resolution
    reconFrame3 = imresize(reconFrame3,[resolution resolution]);
end

if size(GtFrame,1)~= resolution
    GtFrame = imresize(GtFrame,[resolution resolution]);
end

figure
imshow(GtFrame)
[xi,yi] = getpts ;
close all
zoomc = round([yi(1) xi(1) 512]);
chr = [zoomc(1),zoomc(1)+zoomc(3);zoomc(2),zoomc(2)+zoomc(3)];

zF1 = reconFrame1(chr(1,1):chr(1,2),chr(2,1):chr(2,2));
zF2 = reconFrame2(chr(1,1):chr(1,2),chr(2,1):chr(2,2));
zF3 = reconFrame3(chr(1,1):chr(1,2),chr(2,1):chr(2,2));
zGt = GtFrame(chr(1,1):chr(1,2),chr(2,1):chr(2,2));

figure('Color','w','Position',[168 -314 1624 900])
[ha, pos] = tight_subplot(2,4,[.001 .001],[.001 .11],[.01 .01]);
axes(ha(1)); 
ig = imshow(GtFrame);
title("Groundtruth",'interpreter','latex','FontSize',20)
axes(ha(2)); 
i1 = imshow(reconFrame1);
title("RevSCI ",'interpreter','latex','FontSize',20)
axes(ha(3)); 
i2 = imshow(reconFrame2);
title("RevSCI+EDSR ",'interpreter','latex','FontSize',20)
axes(ha(4)); 
i3 = imshow(reconFrame3);
title("RevSCI+VSR ",'interpreter','latex','FontSize',20)
axes(ha(5)); 
igz = imshow(zGt);
axes(ha(6)); 
i1z = imshow(zF1);
axes(ha(7)); 
i2z = imshow(zF2);
axes(ha(8)); 
i3z = imshow(zF3);
stxt = sprintf("$%i\\times %i\\times %i$",resolution,resolution,frames);
sgtitle(stxt,'interpreter','latex','FontSize',20)


%%
RenderComparator = sprintf("%s_COMPARATOR_d%s_sp%i_%ip%if_%sOrder_x%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType,EDSR_SR);
if RenderVideo
  disp("Rendering video")
  %vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.mp4",'MPEG-4');
  vid = VideoWriter(RenderFold+"/"+RenderComparator + "_gray.avi");
  vid.Quality = 100;
  vid.FrameRate = 25;
  open(vid);
  for k = 1:frames
     
    reconFrame1 = im2double(imread(dataRecon1+framesNames1{k}));
    reconFrame1 = reconFrame1(:,:,1);
    reconFrame2 = im2double(imread(dataRecon2+framesNames2{k}));
    reconFrame2 = reconFrame2(:,:,1);
    reconFrame3 = im2double(imread(dataRecon3+framesNames3{k}));
    reconFrame3 = reconFrame3(:,:,1);
    GtFrame = imresize(im2double(imread(dataFolder + vids{k+offset}))...
        ,size(reconFrame1,1:2));

    if size(reconFrame1,1)~= resolution
        reconFrame1 = imresize(reconFrame1,[resolution resolution]);
    end

    if size(reconFrame2,1)~= resolution
        reconFrame2 = imresize(reconFrame2,[resolution resolution]);
    end

    if size(reconFrame3,1)~= resolution
        reconFrame3 = imresize(reconFrame3,[resolution resolution]);
    end

    if size(GtFrame,1)~= resolution
        GtFrame = imresize(GtFrame,[resolution resolution]);
    end

    zF1 = reconFrame1(chr(1,1):chr(1,2),chr(2,1):chr(2,2));
    zF2 = reconFrame2(chr(1,1):chr(1,2),chr(2,1):chr(2,2));
    zF3 = reconFrame3(chr(1,1):chr(1,2),chr(2,1):chr(2,2));  
    zGt = GtFrame(chr(1,1):chr(1,2),chr(2,1):chr(2,2));  
      
    axes(ha(1)); 
    ig.CData = GtFrame;
    title("Groundtruth",'interpreter','latex','FontSize',20)
    axes(ha(2)); 
    i1.CData = reconFrame1;
    title("RevSCI ",'interpreter','latex','FontSize',20)
    axes(ha(3)); 
    i2.CData = reconFrame2;
    title("RevSCI+EDSR ",'interpreter','latex','FontSize',20)
    axes(ha(4)); 
    i3.CData = reconFrame3;
    title("RevSCI+VSR ",'interpreter','latex','FontSize',20)
    axes(ha(5)); 
    igz.CData = zGt;
    axes(ha(6)); 
    i1z.CData = zF1;
    axes(ha(7)); 
    i2z.CData = zF2;
    axes(ha(8)); 
    i3z.CData = zF3;
    stxt = sprintf("$%i\\times %i\\times %i$",resolution,resolution,frames);
    sgtitle(stxt,'interpreter','latex','FontSize',20)
           
    frame = getframe(gcf);
    writeVideo(vid, frame);
    clc
    fprintf("Rendering %i-%i\n",k,frames)
  end
  close(vid)
end
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