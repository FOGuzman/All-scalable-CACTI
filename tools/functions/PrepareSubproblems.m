function [meas,mask,orig] = PrepareSubproblems(full_meas,cod,order,spix,datae)
meas = [];
mask = cod;
orig = [];
rcnt = 1;
for k = 1:spix^2
        SM = full_meas(order(k,1):spix:end,order(k,2):spix:end);
        meas = cat(3,meas,SM);
        SO = datae{k};
        orig = cat(3,orig,squeeze(SO(:,:,:)));
        clc;fprintf('Block (%i,%i) generated\n',order(k,1),order(k,2))
end          
orig = orig*255;
end

