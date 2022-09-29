% Created by: Ph.D Nelson Eduardo Diaz Diaz
% Post-doctorado Pontícia Universidad Católica de Valparaíso (PUCV)
% Date 2 February 2022

% Comparison of minimum distance
% Solution using the Discrete Sphere Packing based on 3D N^2 Queens
% Approach

% Find Optimal values of a and b

function [a,b,ma,G1]=DDDRSNNP3(N,NF)
M = round(NF/2);
distance = zeros(M,M);
x = ones(1,NF)';
y = (1:NF)';
I = kron(x',y);
J = kron(x,y');
nn = round(sqrt(NF));
for i=1:M
    for j=i:M
        G = mod(I.*i + J.*j,NF)+1;
        t = length(unique(G(1:nn,1:nn)));
        if(t == NF)
            [distance(i,j)]=distan3(G,NF);
        else
        end
    end
    disp(i +" out of "+ num2str(M));
end
ma = max(distance(:));
%ma
[b,a,~]= find(ma==distance);
G = mod(I.*a(1) + J.*b(1),NF)+1;
A = G;
p = ceil(N/NF);
B = ones(p,p);
G1 = kron(B,A);
G1 = G1(1:N,1:N);
%save("results/dist_best"+num2str(N),'distance','a','b')
end


function [res]=distan3(G,NF)
%% 3D statistics
[~,N]= size(G);
L = N;
%L = round(sqrt(N));
G = G(1:L,1:L);
[r,c,z] = find(G);
B = [r c z];
T = zeros(L,L);
D = pdist(B);
dist =squareform(D);
for i=1:L^2
    [~,~,values] = find(dist(i,:));
    T(i) = min(values);
    %temp = dist(i,:);
    %T(r(i),c(i)) = min(temp(temp>0));
end
    bmin = min(T(:)); % reach d=3 and density=0.5 although allowing non-uniform
    res = bmin;
end
