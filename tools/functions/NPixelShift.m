function [im_out] = NPixelShift(im_in,N,d)
im_out = zeros(size(im_in),'uint8');
switch d
    case "l"
    im_out(:,1:end-N) = im_in(:,N+1:end);
    case "r"
    im_out(:,N+1:end) = im_in(:,1:end-N);
    case "u"
    im_out(1:end-N,:) = im_in(N+1:end,:);
    case "d"
    im_out(N+1:end,:) = im_in(1:end-N,:);
end
end