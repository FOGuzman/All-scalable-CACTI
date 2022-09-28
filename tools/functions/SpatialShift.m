function [shift_im,kk] = SpatialShift(im_in,order,resolution,k,kk)
shift_im = zeros(resolution,resolution,'uint8');
[ms,ns,fs] = size(im_in);
    
    

    if order(kk,1) > 1
    im_in = NPixelShift(im_in,order(kk,1)-1,"d");
    im_in = im_in((order(kk,1)):end,:);
    end
    if order(kk,2) > 1
    im_in = NPixelShift(im_in,order(kk,2)-1,"r");
    im_in = im_in(:,(order(kk,2)):end);
    end
    
    shift_im((order(kk,1)):end,(order(kk,2)):end) = im_in;
    patch = imresize(im_in,[resolution resolution]);
    shift_im(:,1:(order(kk,2))-1) = patch(:,1:(order(kk,2))-1);
    shift_im(1:(order(kk,1))-1,:) = patch(1:(order(kk,1))-1,:);
    
    if mod(k,8)==0
        kk=kk+1;
    end
    
end