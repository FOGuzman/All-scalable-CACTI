%% Loading video
if exist('RendeFold','var');if ~isfolder(RenderFold);mkdir(RenderFold);end;end
if ~isfolder(dataRecon);mkdir(dataRecon);end
dataFolder = datasetFolder + vidName +"/";
list = dir(dataFolder+"*.tiff");
vids = natsort({list.name});

if size(vids,1) == 0;error("Cannot find video: %s",vidName);end



order = TemporalMosaicGenerator(OrderType,spix);

if UPmethod == "TC"
    PixelAdjust = "no";
end

% Loading masks
cod = MaskLoader(MaskMethod,DEmethod,methodResolution);


% Setting up frames idx
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


% setting prompt
fprintf("||||||||||||||| All-scalable CACTI ||||||||||||||\n")
fprintf("Settings prepared\n")
fprintf("Video name: %s Resolution: %ix%ix%i\n",vidName,resolution,resolution,frames)
fprintf("s = %i, alpha = %i\n",spix,alpha)
fprintf("TM type = %s, PixelAdjust = %s\n",OrderType,PixelAdjust)
fprintf("Demultiplexing method = %s\n",DEmethod)
fprintf("Upscaling method = %s\n",UPmethod)