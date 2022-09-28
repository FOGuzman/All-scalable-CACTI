function [order] = TemporalMosaicGenerator(OrderType,spix)
%% Method to generate the Temporal Mosaic
switch OrderType
    case "normal"                
      order = reshape([1:spix^2],[spix spix])';     
    case "spiral"    
      order = reshape([1:spix^2],[spix spix])';
      order(2:2:end,:) = flip(order(2:2:end,:),2);   
    case "random"
      order = reshape(randperm(spix^2),[spix spix])';      
    case "designed"
      [~,~,~,order]=DDDRSNNP3(spix,spix^2);
    otherwise
      error("Invalid Temporal mosaic")  
end


end

