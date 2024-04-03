clear all;clc;close all
addpath(genpath('./tools'));

datasetFolder = "./dataset/gray/";
vidName = "sticks";


dataRecon = "./large_scale_results/test/" + vidName +"/";
RenderFold = "./large_scale_videos";

Metrics = 1;
RenderVideo = 1;
SaveMask = 0;

DEmethod = "STT";
UPmethod = "VSR";
MaskMethod = "MethodDefined";
OrderType = "spiral";
PixelAdjust = "post";
SwapSensing = 0;
B = 8;
spix = 8;
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


vid = VideoWriter(RenderFold+"/"+vidName + "_gray.avi");
vid.Quality = 100;
if max(forder) > 25
vid.FrameRate = 25;
else
vid.FrameRate = round(max(forder)/2); 
end
open(vid);




for k = 1:spix^2
      
      if k>length(vids)
        offset = -length(vids)+1;
      end
      
      vidFrame = StreamNframes(dataFolder,vids,sf,cont,offset,frames,forder,resolution,spix,"Gray");      
      for mm= 1:size(vidFrame,3)
          writeVideo(vid, vidFrame(:,:,mm));
      end
      
      
      clc
      fprintf("Generating measure data (%i/%i)\n",order(k,1),order(k,2))
      cont = cont+1;
%% Perform video metric and render video.
end
close(vid)

  

