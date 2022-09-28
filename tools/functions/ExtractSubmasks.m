function [smask1] = ExtractSubmasks(cod,Reg,k,spix,resolution,frames)
if sqrt(size(Reg,1)) ~= spix
    error("Subpixel register must be equal to spix")
end

smask1 = zeros(resolution,resolution,frames/(spix^2),'logical'); 
smask1(Reg(k,1):spix:end,Reg(k,2):spix:end,:) = cod;
end

