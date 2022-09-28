function [Reg] = VectorOrder(order,spix)
for o = 1:spix^2
[a,b] = find(order == o);
Reg(o,1) = a; Reg(o,2)=b;
end
end

