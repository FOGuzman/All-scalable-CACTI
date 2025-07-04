switch UPmethod    
    case "TC"
    %% Tensor completion    
    addpath(genpath("./tools/methods/DP3LRTC")) 
    
    opts = [ ];
    opts.tol   = 1e-4;
    opts.maxit = 200;
    %opts.Xtrue = X_GT;
    opts.debug = 0;
    opts.sigma = 0.5;
    opts.beta1 = 2;
    opts.beta2 = 2;
    %opts.rho   = 1.01;
    %             opts.maxbeta = 5;
    delete(dataRecon+"*.png")
    fwnd = 32;
    rwnd = 256;
    fprintf('Applying DP3LRTC Tensor Completion');
    kk=1;
    sfa = reshape([1:size(pic_up,3)],B,[])';
    adorder = reshape(forder,B,[])';
    for k = 1:size(sfa,1)
    pic_up_r{k} = pic_up(:,:,sfa(k,:));
    end
    
    sframe=zeros(resolution,resolution,fwnd,'uint8');
    tcmask = logical(sframe);
    fr = 1;scnt= 1;
    
    for f = 1:max(forder)
    clc;fprintf('Applying DP3LRTC Tensor Completion for (%i/%i)\n',scnt,max(forder));
    [kk,fp] = find(adorder==f);
    fpp = find(forder==f);
    %aux = pic_up(:,:,fp(k));
    for k = 1:length(kk)
    sframe(order(kk(k),1):spix:end,order(kk(k),2):spix:end,fr) = pic_up(:,:,fpp(k)); 
    tcmask(order(kk(k),1):spix:end,order(kk(k),2):spix:end,fr) = ones(size(pic_up(:,:,fpp(k))));
    end
    
    
       
    if mod(f,fwnd) == 0 || f==max(forder)
     
     if f==max(forder)
       vals = squeeze(sum(sum(sframe,1),2) )' ;
       cuts = find(vals~=0);
       tcmask = tcmask(:,:,cuts) ; 
       sframe = sframe(:,:,cuts) ;
       fwnds = max(cuts);
     else
       fwnds = fwnd;  
     end
     
     Xr = zeros(resolution,resolution,fwnds);
     for r2 = 1:resolution/rwnd
     for r1 = 1:resolution/rwnd
     aux_miss = tcmask((r1-1)*rwnd+1:r1*rwnd,(r2-1)*rwnd+1:r2*rwnd,:);
     aux_meas = sframe((r1-1)*rwnd+1:r1*rwnd,(r2-1)*rwnd+1:r2*rwnd,:);
     
     
     Omega = sort(find(~aux_miss==0));
     [x] = admm_DP3LR( im2double(aux_meas), Omega, opts ); 
     
     Xr((r1-1)*rwnd+1:r1*rwnd,(r2-1)*rwnd+1:r2*rwnd,:) = x;
     end
     end
     for sfr = 1:size(Xr,3)
        fname = sprintf("f_%i_gray.png",scnt);
        imwrite(Xr(:,:,sfr),dataRecon+fname); 
        scnt = scnt+1;
     end
     
     fr = 0;
     sframe=zeros(resolution,resolution,fwnd,'uint8');
     tcmask = sframe;

    end
    
    fr = fr+1;
    end
    
    

    
 
    case "2DI"
    %% 2D interpolation       
    delete(dataRecon+"*.png")
    if ~isfolder(dataRecon);mkdir(dataRecon);end
    fprintf('Applying 2D Interpolation');
    kk = 1;
    for k = 1:size(pic_up,3)
    clc;fprintf('Applying 2D Interpolation for (%i/%i)\n',k,size(pic_up,3));
    dem = pic_up(:,:,k);
    aux = imresize(dem,EDSR_SR,'bilinear');
    if PixelAdjust == "post"
    [aux, kk]= SpatialShift(aux,order,resolution,k,kk);
    end
    fname = sprintf("f_%i_gray.png",k);
    imwrite(aux,dataRecon+fname);
    end
        
        
    case "3DI" 
    %% 3D Interpolation    
        delete(dataRecon+"*.png")
        fprintf('Applying 3D Interpolation');
        bc = 1;kk=1;
        for b3 = 1:spix^2
            aux =  pic_up(:,:,(b3-1)*B+1:b3*B);
            aux = imresize3(aux,[resolution resolution B]);           
            for k= 1:B
            fname = sprintf("f_%i_gray.png",bc);
            if PixelAdjust == "post"
             [aux_r, kk]= SpatialShift(aux(:,:,k),order,resolution,bc,kk);
            else
              aux_r = aux(:,:,k);
            end
            clc;fprintf('Applying 3D Interpolation for (%i/%i)\n',bc,size(pic_up,3));    
            imwrite(aux_r,dataRecon+fname);
            bc=bc+1;
            end 
        end
        
    case "EDSR"
    %% 2D Super Resolution    
        EDSR_settings
        delete(EDSR_testpath+"*.png")
        delete(EDSR_reconpath+"*.png")
        fprintf('Applying EDSR for %dx SR\n', EDSR_SR);
        bc = 1;kk=1;
        for b3 = 1:spix^2
            aux =  pic_up(:,:,(b3-1)*B+1:b3*B);
            aux = imresize3(aux,[resolution resolution B]);           
            for k= 1:B
            fname = sprintf("f_%i_gray.png",bc);
            if PixelAdjust == "post"
             [aux_r, kk]= SpatialShift(aux(:,:,k),order,resolution,bc,kk);
            else
              aux_r = aux(:,:,k);   
            end
            clc;fprintf('Preparing images for EDSR (%i/%i)\n',bc,size(pic_up,3));    
            imwrite(imresize(aux_r,resolution/spix*[1 1]),EDSR_testpath+fname);
            bc=bc+1;
            end 
        end
               
        systxt = system(execEDSR);
        if systxt ~= 0; error("Error in EDSR python script");end
        delete(dataRecon+"*.png")
        movefile(EDSR_reconpath+"*.png",dataRecon)
        
        if PixelAdjust == "post"
           kk=1; 
           list = dir(dataRecon+"*.png");
           framesNames = natsort({list.name});
           for k = 1:frames
               clc;fprintf('Correcting subpixel for (%i/%i)\n',k,size(pic_up,3));  
               aux = imread(dataRecon+framesNames{k});
               if size(aux,1)<resolution || size(aux,1)>resolution
                   aux = imresize(aux,[resolution resolution]);
               end
               imwrite(aux,dataRecon+framesNames{k})
           end
        end
        
        
        
    
    case "VSR"
    %% Video Super Resolution    
        VSR_settings
        delete(VSR_testpath+"*.png")
        delete(VSR_reconpath+"*.png")
        fprintf('Applying VSR for %dx SR\n', EDSR_SR);
        if ~isfolder(VSR_testpath);mkdir(VSR_testpath);end
        bc = 1;kk=1;
        for b3 = 1:spix^2
            aux =  pic_up(:,:,(b3-1)*B+1:b3*B);
            aux = imresize3(aux,[resolution resolution B]);
            for k= 1:B
            fname = sprintf("f_%i_gray.png",bc);
            if PixelAdjust == "post"
             [aux_r, kk]= SpatialShift(aux(:,:,k),order,resolution,bc,kk);
            else
              aux_r = aux(:,:,k);
            end
            clc;fprintf('Preparing images for VSR (%i/%i)\n',bc,size(pic_up,3));    
            imwrite(imresize(aux_r,resolution/spix*[1 1]),VSR_testpath+fname);
            bc=bc+1;
            end 
        end
        
        systxt = system(execVSR);if systxt ~= 0; error("Error in VSR python script");end
        
        delete(dataRecon+"*.png")
        movefile(VSR_reconpath+"*.png",dataRecon) 
        if PixelAdjust == "post"
           list = dir(dataRecon+"*.png");
           framesNames = natsort({list.name});
           for k = 1:frames
               clc;fprintf('Correcting subpixel for (%i/%i)\n',k,size(pic_up,3));  
               aux = imread(dataRecon+framesNames{k});
               if size(aux,1)<resolution || size(aux,1)>resolution
                   aux = imresize(aux,[resolution resolution]);
               end
               imwrite(aux,dataRecon+framesNames{k})
           end
        end
        
        
        
     case "VSR++"
     %% Video Super Resolution ++    
        VSRpp_settings
        delete(VSRpp_testpath+"*.png")
        delete(VSRpp_reconpath+"*.png")
        fprintf('Applying VSR++ for %dx SR\n', EDSR_SR);
        if ~isfolder(VSRpp_testpath);mkdir(VSRpp_testpath);end
        bc = 1;kk=1;
        for b3 = 1:spix^2
            aux =  pic_up(:,:,(b3-1)*B+1:b3*B);
            aux = imresize3(aux,[resolution resolution B]);
            for k= 1:B
            fname = sprintf("f_%i_gray.png",bc);
            if PixelAdjust == "post"
             [aux_r, kk]= SpatialShift(aux(:,:,k),order,resolution,bc,kk);
            else
              aux_r = aux(:,:,k);
            end
            clc;fprintf('Preparing images for VSR++ (%i/%i)\n',bc,size(pic_up,3));    
            imwrite(imresize(aux_r,resolution/spix*[1 1]),VSRpp_testpath+fname);
            bc=bc+1;
            end 
        end
        systxt = system(execVSRpp);if systxt ~= 0; error("Error in VSR++ python script");end
        delete(dataRecon+"*.png")
        movefile(VSRpp_reconpath+"*.png",dataRecon) 
        if PixelAdjust == "post"
           kk=1; 
           list = dir(dataRecon+"*.png");
           framesNames = natsort({list.name});
           for k = 1:frames
               clc;fprintf('Correcting subpixel for (%i/%i)\n',k,size(pic_up,3));  
               aux = imread(dataRecon+framesNames{k});
               if size(aux,1)<resolution || size(aux,1)>resolution
                   aux = imresize(aux,[resolution resolution]);
               end
               imwrite(aux,dataRecon+framesNames{k})
           end
        end 

        
  case "VINR"
     %% Video Super Resolution ++    
        VideoINR_settings
        delete(VINR_testpath+"*.png")
        delete(VINR_reconpath+"*.png")
        fprintf('Applying VideoINR for %dx SR\n', spix);
        if ~isfolder(VINR_testpath);mkdir(VINR_testpath);end
        bc = 1;kk=1;
        for b3 = 1:spix^2
            aux =  pic_up(:,:,(b3-1)*B+1:b3*B);
            aux = imresize3(aux,[resolution resolution B]);
            for k= 1:B
            fname = sprintf("f_%i_gray.png",bc);
            if PixelAdjust == "post"
             [aux_r, kk]= SpatialShift(aux(:,:,k),order,resolution,bc,kk);
            else
              aux_r = aux(:,:,k);
            end
            clc;fprintf('Preparing images for VideoINR (%i/%i)\n',bc,size(pic_up,3));    
            imwrite(imresize(aux_r,resolution/spix*[1 1]),VINR_testpath+fname);
            bc=bc+1;
            end 
        end
        systxt = system("conda run -n videoinr "+execVINR);if systxt ~= 0; error("Error in VideoINR python script");end
        delete(dataRecon+"*.png")
        movefile(VINR_reconpath+"*.png",dataRecon) 
        if PixelAdjust == "post"
           kk=1; 
           list = dir(dataRecon+"*.png");
           framesNames = natsort({list.name});
           for k = 1:frames-1
               clc;fprintf('Correcting subpixel for (%i/%i)\n',k,size(pic_up,3));  
               aux = imread(dataRecon+framesNames{k});
               if size(aux,1)<resolution || size(aux,1)>resolution
                   aux = imresize(aux,[resolution resolution]);
               end
               imwrite(aux,dataRecon+framesNames{k})
           end
        end         
        
        
        
    otherwise
        
    error("Invalid Upscaling method")    
        
end


