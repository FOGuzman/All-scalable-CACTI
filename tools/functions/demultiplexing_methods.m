switch DEmethod
    
    
% RevSCI    
case "RevSCI"
    if ~isfolder("./tools/methods/RevSCI-net-master/ExtremeCacti_in")
    mkdir("./tools/methods/RevSCI-net-master/ExtremeCacti_in")
    end
    if ~isfolder("./tools/methods/RevSCI-net-master/ExtremeCacti_out")
        mkdir("./tools/methods/RevSCI-net-master/ExtremeCacti_out")
    end
    delete("./tools/methods/RevSCI-net-master/ExtremeCacti_out/*.mat")
    save("./tools/methods/RevSCI-net-master/ExtremeCacti_in/data_in.mat",'meas','mask','orig')
    clear datae par_meas subMask subMeas vidFrame
    disp("------------- Sending to RevSCI model -----------")
    tic
    systxt = system('python ./tools/methods/RevSCI-net-master/recon_extreme_cacti.py');
    if systxt ~= 0; error("Error in RevSCI python script");end
    disp("------------- Reconstruction done -----------")
    load("./tools/methods/RevSCI-net-master/ExtremeCacti_out/data_out.mat");

    pic_up = PytorchReconReshapeGray(pic,frames);
    recon_raw = pic_up;
    
 
% SCI3D    
    case "SCI3D"
    
    if ~isfolder("./tools/methods/SCI3D-main/ExtremeCacti_in")
    mkdir("./tools/methods/SCI3D-main/ExtremeCacti_in")
    end
    if ~isfolder("./tools/methods/SCI3D-main/ExtremeCacti_out")
        mkdir("./tools/methods/SCI3D-main/ExtremeCacti_out")
    end    
    delete("./tools/methods/SCI3D-main/ExtremeCacti_out/*.mat")
    save("./tools/methods/SCI3D-main/ExtremeCacti_in/data_in.mat",'meas','mask','orig')
    clear datae par_meas subMask subMeas vidFrame
    disp("------------- Sending to SCI3D model -----------")
    tic
    systxt = system('python ./tools/methods/SCI3D-main/recon_extreme_cacti.py');
    if systxt ~= 0; error("Error in SCI3D python script");end
    disp("------------- Reconstruction done -----------")
    load("./tools/methods/SCI3D-main/ExtremeCacti_out/data_in.mat");

    [pic_up] = PytorchReconReshapeGray(pic,frames);
    recon_raw = pic_up;
    
    
% STT    
    case "STT"
    
    if ~isfolder("./tools/methods/STFormer-main/test_datasets/simulation")
    mkdir("./tools/methods/STFormer-main/test_datasets/simulation")
    end
    if ~isfolder("./tools/methods/STFormer-main/out/test_images")
        mkdir("./tools/methods/STFormer-main/out/test_images")
    end    
    delete("./tools/methods/STFormer-main/test_datasets/simulation/*.mat")
    save("./tools/methods/STFormer-main/test_datasets/simulation/data_in.mat",'meas','mask','orig')
    save("./tools/methods/STFormer-main/test_datasets/mask/mask.mat",'mask')
    clear datae par_meas subMask subMeas vidFrame
    disp("------------- Sending to ST Transformer model -----------")
    tic
    systxt = system('python ./tools/methods/STFormer-main/tools/test.py ./tools/methods/STFormer-main/configs/STFormer/stformer_base.py --weights=./tools/methods/STFormer-main/checkpoints/stformer_base.pth --work_dir=./tools/methods/STFormer-main/out --mask_path=./tools/methods/STFormer-main/test_datasets/mask/mask.mat');
    if systxt ~= 0; error("Error in Spatio Temporal Transformer python script");end
    disp("------------- Reconstruction done -----------")
    load("./tools/methods/STFormer-main/out/test_images/data.mat");

    [pic_up] = PytorchReconReshapeGray(recon,frames);
    recon_raw = pic_up;
    
        
% GAP-TV

    case "GAP-TV"
     
    disp("Applying GAP-TV...")    
    GAP_TV_propeties_setting;    
    [pic_up] = gapdenoise_cacti(mask,meas*255,orig,[],para);   
    pic_up(pic_up<0) = 0;pic_up(pic_up>1) = 1;
    pic_up = uint8(pic_up*255);
    recon_raw = pic_up;
    disp("Done")

    
    
% DeSCI
    
    case "DeSCI"
        
    disp("Applying DeSCI...")    
    DeSCI_propeties_setting;    
    [pic_up] = gapdenoise_cacti(mask,meas*255,orig,[],para);   
    pic_up(pic_up<0) = 0;pic_up(pic_up>1) = 1;
    pic_up = uint8(pic_up*255);
    recon_raw = pic_up;
    disp("Done")    
    
        
end