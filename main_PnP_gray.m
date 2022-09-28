clear all;clc;close all
addpath(genpath('./DeSCI-master')); % algorithms
addpath('functions');
addpath('largescale_functions')

vidName = "mayo";

dataFolder = "./dataset_largescale/gray/" + vidName +"/";
dataRecon = "./large_scale_results/test/" + vidName +"/";
if ~isfolder(dataRecon);mkdir(dataRecon);end
list = dir(dataFolder+"*.tiff");
vids = natsort({list.name});

Metrics = 1;
RenderVideo = 1;
SaveMask = 0;

RenderFold = "./large_scale_videos";
if ~isfolder(RenderFold);mkdir(RenderFold);end

DEmethod = "STT";
UPmethod = "2DI";
OrderType = "spiral";
PixelAdjust = "post";
StreamMode = "sequential";
SwapSensing = 0;
B = 8;
spix = 8;
frames = spix^2*B;
resolution = 256*spix;
alpha = B;


switch OrderType
    case "normal"                
      order = reshape([1:spix^2],[spix spix])';     
    case "spiral"    
      order = reshape([1:spix^2],[spix spix])';
      order(2:2:end,:) = flip(order(2:2:end,:),2);   
    case "random"
      order = reshape(randperm(spix^2),[spix spix])';      
    case "designed"
      [~,~,~,order]=DDDRSNNP3(spix,spix^2);  
end


% Loading masks
EDSR_SR = spix;
if DEmethod == "RevSCI" || DEmethod == "GAP-TV"
cod = load('./RevSCI-net-master/train/mask');cod = cod.mask;
end

if DEmethod == "SCI3D"
cod = load('./SCI3D-main/simulation_dataset/traffic.mat');cod = cod.mask;
end

if DEmethod == "STT"
cod = load('./STFormer-main/trained_mask.mat');cod = logical(cod.mask);
end


if UPmethod == "TC"
    PixelAdjust = "no";
end


%%Designed
nmask = cat(3,[0 0 1 1;0 1 0 0;1 1 0 1;0 0 1 0],[1 0 0 1;0 1 0 0;1 0 0 1;0 0 0 0],...
    [1 0 0 1;0 0 1 0;0 0 0 1;1 0 1 0],[0 0 0 0;1 1 1 0;0 0 0 0;1 0 1 1],...
    [0 0 1 0;1 0 1 0;0 1 1 0;1 0 0 1],[0 1 1 0;1 0 0 0;1 0 1 0;0 0 0 1],...
    [0 0 0 0;1 0 0 1;0 0 1 1;0 1 0 1],[1 1 0 0;0 0 1 1;0 1 0 0;0 1 0 0]);

cod = [];
for k = 1:8
u = kron(ones(64,64),nmask(:,:,k));
cod = cat(3,u,cod);
end


forder = [1:B];
aux = forder;
for k = 2:spix^2
   forder = cat(2,forder,aux+alpha*(k-1)) ;
end 

if SwapSensing
    Mm = spix^2*alpha+B-alpha;
    L = spix^2*alpha+1;
   for k = 1:length(forder)
       if forder(k) >= L
        forder(k) = forder(k)-(L-1);
       end
   end
   L = spix^2*alpha;

else
    L = spix^2*alpha+B-alpha;
end

if alpha == 0; L = B; end


%plot_sensing();

RenderName = sprintf("%s_square_d%s_sp%i_%ip%if_%sOrder_%sx%i_PixAdj%sUp_alpha%i",...
    vidName,DEmethod,spix,resolution,frames,OrderType,UPmethod,EDSR_SR,PixelAdjust,alpha);
fprintf("%s\n",RenderName)
%% Load and sampling
cont = 1;
offset = 0;
full_meas = zeros(resolution,resolution);
full_mask = logical([]);
sf = reshape([1:frames],frames/(spix^2),[])';
smallorig = [];
orgcont = 1;mcont=1;
order = VectorOrder(order,spix);
for k = 1:spix^2
      
      if k>length(vids)
        offset = -length(vids)+1;
      end
      
      [vidFrame] = StreamNframes(dataFolder,vids,sf,cont,offset,frames,forder,resolution,spix,"Gray");
%       sl = vidFrame(:,:,8);
%       sl = zeros(resolution,resolution);
%       sl(resolution/2-spix/2:resolution/2+spix/2-1,resolution/2-spix/2:resolution/2+spix/2-1) = 8*ones(spix,spix);
%       vidFrame = cat(3,sl,sl,sl,sl,sl,sl,sl,sl);
%       
      SubMask = CrateMaskRevSCI(cod,order,k,spix,resolution,frames);
      full_meas = full_meas + sum(vidFrame.*SubMask,3);
      if SaveMask
          if mcont==1
          full_mask = zeros(resolution,resolution,B+(alpha)*(spix^2-1),'logical') ;
          end
          full_mask(:,:,forder((mcont-1)*B+1:mcont*B)) =...
              full_mask(:,:,forder((mcont-1)*B+1:mcont*B)) +  SubMask;
          mcont = mcont+1;
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

%% Preparing subproblems

[meas,mask,orig] = PrepareSubproblems(full_meas,cod,order,spix,datae);

% point source
% meas = zeros(256,256,spix^2);
% for k = 1:spix^2
%     meas(128,128,k) = 8;
% end

%% Demultiplexing
demultiplexing_methods


%% Adjust subpixel pre Upscaling
if PixelAdjust == "pre"
    kk= 1;
    for m = 1:frames
        if order(kk,2)>1 ||  order(kk,1)>1
        pic_up(:,:,m) = uint8(imshift_fft([order(kk,2)-1 (order(kk,1)-1)]/spix,recon_raw(:,:,m))); 
        end
        if mod(m,B)==0
        kk=kk+1;
        end
    end
end


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

if RenderVideo
    disp("Rendering video")
    %vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.mp4",'MPEG-4');
    vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.avi");
    vid.Quality = 100;
    if max(forder) > 25;
    vid.FrameRate = 25;
    else
    vid.FrameRate = round(max(forder)/2); 
    end
    open(vid);
    list = dir(dataRecon+"*.png");
    rframe = natsort({list.name});
    for k = 1:length(rframe)

        frame = imread(dataRecon+rframe{k});
        writeVideo(vid, frame);
        clc
        fprintf("Rendering %i-%i\n",k,max(forder))
    end
    close(vid)
end
  




if Metrics
    v_psnr = [];
    v_ssim = [];
    fprintf("Calculating PSNR SSIM\n")
    list = dir(dataRecon+"*.png");
    framesNames = natsort({list.name});
    for k = 1:max(forder) 
        
        frame = imread(dataRecon+framesNames{k});
        reconFrame = im2double(frame);
        reconFrame = reconFrame(:,:,1);
        
        
        
        GtFrame = imresize(im2double(imread(dataFolder + vids{k+offset})),size(reconFrame,1:2));
        
        if PixelAdjust == "post"   
        v_psnr(k) = psnr(GtFrame(spix:end-spix,spix:end-spix)...
                        ,reconFrame(spix:end-spix,spix:end-spix));
        v_ssim(k) = ssim(GtFrame(spix:end-spix,spix:end-spix)...
                        ,reconFrame(spix:end-spix,spix:end-spix));
        else
        v_psnr(k) = psnr(GtFrame,reconFrame);
        v_ssim(k) = ssim(GtFrame,reconFrame);    
        end    
        clc;fprintf('Calculating PSNR SSIM\n Frame %i | psnr = %.2f mean = %.2f | ssim = %.4f mean = %.4f\n'...
            ,k,v_psnr(k),mean(v_psnr),v_ssim(k),mean(v_ssim));
    end
    save(RenderFold+"/"+RenderName + "_metrics.mat",'v_psnr','v_ssim','full_meas','full_mask')
end


file = fopen(RenderFold+"/"+RenderName+"_log.txt",'w');
fprintf(file,"Video Name:                  %s\n",vidName);
fprintf(file,"Resolution:                  %i x %i\n",resolution,resolution);
fprintf(file,"Frames:                      %i\n",frames);
fprintf(file,"Super Pixel Used:            %i x %i\n",spix,spix);
fprintf(file,"Sampling Order:              %s\n",OrderType);
fprintf(file,"Demultiplexing Method:       %s\n",DEmethod);
fprintf(file,"Upscaling Method:            %s\n",UPmethod);
fprintf(file,"Upscaling Factor:            x%i\n",EDSR_SR);
fprintf(file,"Pixel shift adjustement:     %sUpscaling\n",PixelAdjust);
fprintf(file,"Mean PSNR:                   %2.2f dB\n",mean(v_psnr));
fprintf(file,"Std PSNR:                    %2.2f dB\n",std(v_psnr));
fprintf(file,"Mean SSIM:                   %.4f \n",mean(v_ssim));
fprintf(file,"Std SSIM:                    %.4f \n",std(v_ssim));
fprintf(file,"Date:                        %s \n",datetime);
fclose(file);
