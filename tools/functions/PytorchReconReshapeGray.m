function [pic_up,subaux] = PytorchReconReshapeGray(pic,frames)
[M N F S] = size(pic);
pic = permute(pic,[3 4 2 1]);
if M>1
aux = [];
sf = reshape([1:M],M/2,[])';
pic_up = zeros(size(pic,1),size(pic,2),frames);
subaux = [];
for k = 1:size(pic,4)
    aux = pic(:,:,:,k);
    subaux = cat(3,subaux,aux);
end
else
    subaux = pic;
end
pic_up = subaux;
pic_up(pic_up<0) = 0;pic_up(pic_up>1) = 1;
pic_up = uint8(255*pic_up);
end