function [pic_up] = FourierShift(recon_raw,order,spix,B)
    pic_up = zeros(size(recon_raw),'uint8');
    frames = size(recon_raw,3);
    kk= 1;
    for m = 1:frames
        if order(kk,2)>1 ||  order(kk,1)>1
        pic_up(:,:,m) = uint8(imshift_fft([order(kk,2)-1 (order(kk,1)-1)]/spix,recon_raw(:,:,m))); 
        else
        pic_up(:,:,m) = recon_raw(:,:,m);    
        end
        if mod(m,B)==0
        kk=kk+1;
        end
    end
end

function[shiftim] = imshift_fft(shift,fr)
sz = size(fr);
%mesh of fourier frequencies
[xf,yf] = meshgrid( ((-sz(1)/2+1):1:sz(1)/2)./(sz(1)) , ((-sz(2)/2+1):1:sz(2)/2)./(sz(2)) ); 
F = fftshift( fft2( fr ));
Fshift=  F.*exp(-1i*(2*pi.*(xf*shift(1) + yf*shift(2))) );
shiftim = real(ifft2(ifftshift( Fshift  )));
end