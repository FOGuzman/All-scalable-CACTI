function [cod] = MaskLoader(MaskMethod,DEmethod,Res)
%% Designed mask loader

switch MaskMethod
    
    case "MethodDefined"
    % Loading masks
     switch DEmethod
         
         case "RevSCI"
           cod = load('./tools/methods/RevSCI-net-master/train/mask');cod = cod.mask;
         case "SCI3D"  
           cod = load('./tools/methods/SCI3D-main/simulation_dataset/traffic.mat');cod = cod.mask;
         case "STT"
           cod = load('./tools/methods/STFormer-main/trained_mask.mat');cod = logical(cod.mask);
         otherwise
           cod = load('./tools/methods/RevSCI-net-master/train/mask');cod = cod.mask;  
    
     end
    
    case "Experimental" 
         cod = load('./test_files/gigachad_mask.mat');cod = cod.mask;

    case "Designed"
    %%Designed
    nmask = cat(3,[0 0 1 1;0 1 0 0;1 1 0 1;0 0 1 0],[1 0 0 1;0 1 0 0;1 0 0 1;0 0 0 0],...
        [1 0 0 1;0 0 1 0;0 0 0 1;1 0 1 0],[0 0 0 0;1 1 1 0;0 0 0 0;1 0 1 1],...
        [0 0 1 0;1 0 1 0;0 1 1 0;1 0 0 1],[0 1 1 0;1 0 0 0;1 0 1 0;0 0 0 1],...
        [0 0 0 0;1 0 0 1;0 0 1 1;0 1 0 1],[1 1 0 0;0 0 1 1;0 1 0 0;0 1 0 0]);
    msize = Res/size(nmask,1);
    cod = [];
    for k = 1:8
    u = kron(ones(msize,msize),nmask(:,:,k));
    cod = cat(3,u,cod);
    end

    otherwise
        error("Incorrect design method")
        
end

end

