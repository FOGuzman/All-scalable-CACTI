clear all;clc;close all
addpath(genpath('./tools'));


video_path = "./large_scale_videos_exp/";
meas_path = "./test_files/best/street/";
save_path = "./figures/";


video_names = {dir(video_path+"*.avi").name};video_name = natsort(video_names);
meas_names = {dir(meas_path+"*.tiff").name};meas_name = natsort(meas_names);
save_name = "SupVid1.avi";
fig_name = "ExpResults1.pdf";


%% Supplemental
v = VideoReader(video_path+video_names{1});
fr = 1;

for k = 1:length(meas_names)
mframe(:,:,k) = imread(meas_path+meas_names{k});
end
vframes = read(v,[1 Inf]);vframes = squeeze(vframes(:,:,1,:));


%%
vw = VideoWriter(save_path+save_name);
vw.FrameRate = 60;
vw.Quality = 100;

fig = figure('Color','w','Position',[10 97 1907 714]);

ha = tight_subplot(1,2,[.01 .01],[.01 .01],[.01 .01]);

axes(ha(1))
ax1 = imagesc(mframe(:,:,1));axis image;axis off;colormap gray
txt1 = annotation('textbox', [0.015 0.95 0.2 0.04],'FontSize',24, ...
  'Color',[1 1 0],'LineStyle','none', 'String', "Measurement N° 1");

axes(ha(2))
ax2 = imagesc(vframes(:,:,1));axis image;axis off;colormap gray
txt2 = annotation('textbox', [0.51 0.95 0.4 0.04],'FontSize',24, ...
  'Color',[1 1 0],'LineStyle','none', 'String', "Frame N° 1 | Time 0[ms]");

exportgraphics(fig,save_path+fig_name);
%% Start loop
open(vw)
totalFrames = 8*512;
mc = 1;fc = 1;fps = 410;
for k = 1:totalFrames
    
   if mod(k,512) ==0 && k<totalFrames
       mc = mc+1;
       v = VideoReader(video_path+video_names{mc});    
       vframes = read(v,[1 Inf]);vframes = squeeze(vframes(:,:,1,:));
       fc = 1;
   end
ax1.CData = mframe(:,:,mc);
ax2.CData = vframes(:,:,fc);
txt1.String = sprintf("Measurement N° %i",mc);
txt2.String = sprintf("Frame N° %i | Time %.2f[s]",k,1/fps*k);
drawnow
frame = getframe(fig);
writeVideo(vw, frame);

fc =fc+1;
end

close(vw)