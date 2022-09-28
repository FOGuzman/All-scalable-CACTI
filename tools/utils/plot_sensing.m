fvect = reshape(forder,B,[])';
or = order';
figure('Color','w','Position',[3 114 1913 475]),
subplot(1,4,[2:4])
hold on
for k = 1:size(fvect,1)
plot(fvect(k,:),or(k)*ones(1,B),'sr','LineWidth',5)
end
grid on;box on;xlim([0 max(forder)+1]);ylim([0 spix^2+1])
set(gca,'XTick',1:L);set(gca,'YTick',1:spix^2)
set(gca,'YDir','reverse')
xlabel("Frames",'interpreter','latex','FontSize',16)
ylabel("$\mathbf{M}_k$",'interpreter','latex','FontSize',16)
title("Sampling design, Order: " + OrderType,'interpreter','latex','FontSize',16)
subplot(1,4,1)
plottable(order,'%i');
title("Temporal mosaic k",'interpreter','latex','FontSize',16)
drawnow