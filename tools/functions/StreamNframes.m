function [vidFrame,crop_cor] = StreamNframes(dataFolder,vids,sf,cont,offset,frames,forder,resolution,spix,vidType)

for collect = 1:frames/(spix^2)
          extractedframe = im2double(imread(dataFolder + vids{forder(sf(cont,collect))+offset} ));
          [m n a] = size(extractedframe);
          if size(extractedframe,1)< size(extractedframe,2)
          
          pd = (n-m)/2;         
          extractedframe = cat(1,zeros(pd,n,a),extractedframe,zeros(pd,n,a));
          crop_cor = [pd,pd+m];
          else
              crop_cor = [0 m];
          end
          if size(extractedframe,1) ~= resolution && size(extractedframe,2) ~= resolution
              extractedframe = imresize(extractedframe,[resolution resolution]);
          end
          if vidType == "Color"
            vidFrame(:,:,:,collect) = extractedframe;
          end
          if vidType == "Gray"
              vidFrame(:,:,collect) = extractedframe;
          end
      
end
end

