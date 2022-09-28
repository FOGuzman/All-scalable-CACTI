function [pic_up] = FourierShift(recon_raw,order,spix,B)
    pic_up = zeros(size(recon_raw),'uint8');
    frames = size(recon_raw,3);
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

