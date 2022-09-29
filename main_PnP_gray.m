clear all;clc;close all
addpath(genpath('./tools'));

datasetFolder = "./dataset/gray/";
vidName = "dogo1";


dataRecon = "./large_scale_results/test/" + vidName +"/";
RenderFold = "./large_scale_videos";

Metrics = 1;
RenderVideo = 1;
SaveMask = 0;

DEmethod = "SCI3D";
UPmethod = "EDSR";
MaskMethod = "MethodDefined";
OrderType = "spiral";
PixelAdjust = "post";
SwapSensing = 0;
B = 8;
spix = 2;
frames = spix^2*B;
methodResolution = 256;
resolution = methodResolution*spix;
alpha = B;
EDSR_SR = spix;

setting_propeties();
%% Load and sampling loop
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
      
      vidFrame = StreamNframes(dataFolder,vids,sf,cont,offset,frames,forder,resolution,spix,"Gray");      
      SubMask  = ExtractSubmasks(cod,order,k,spix,resolution,frames);
      full_meas = full_meas + sum(vidFrame.*SubMask,3);
      if SaveMask
          if mcont==1
          full_mask = zeros(resolution,resolution,B+(alpha)*(spix^2-1),'logical') ;
          end
          full_mask(:,:,forder((mcont-1)*B+1:mcont*B)) =...
              full_mask(:,:,forder((mcont-1)*B+1:mcont*B)) +  SubMask;
          mcont = mcont+1;
      end
      smallorig = cat(3,smallorig,vidFrame(order(k,1):spix:end,order(k,2):spix:end,:));
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

if RenderVideo
    disp("Rendering video")
    vid = VideoWriter(RenderFold+"/"+RenderName + "_gray.avi");
    vid.Quality = 100;
    if max(forder) > 25
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
