metricFold = "../../large_scale_metrics_results/comparing_all/";
list = dir(metricFold+"*.mat");list = natsort({list.name});
r = load(metricFold+list{1});
Method = r.Results.DemultiplexingMethod(1) + " + " + r.Results.UpscalingMethod(1);
Resolution = r.Results.Resolution(1);
Metric = sprintf("%.2f ± %.2f  %.4f ± %.4f", ...
    r.Results.UpscalingPSNR(11),r.Results.UpscalingPSNR(12), r.Results.UpscalingSSIM(11),r.Results.UpscalingSSIM(12));



MethodList = [];
for k = 1:length(list);
   r = load(metricFold+list{k});
Method = r.Results.DemultiplexingMethod(1) + " + " + r.Results.UpscalingMethod(1); 
MethodList = cat(1,MethodList,Method);
end

MethodList = unique(MethodList);





FullResult = cell(length(MethodList)+1,4);
FullResult{1,1} = "Method"; 
FullResult{1,2} = "512×512×32"; 
FullResult{1,3} = "1024×1024×128"; 
FullResult{1,4} = "2048×2048×512";
for k = 1:length(list)
r = load(metricFold+list{k});    
Metric = sprintf("%.2f ± %.2f  %.4f ± %.4f", ...
    r.Results.UpscalingPSNR(11),r.Results.UpscalingPSNR(12), r.Results.UpscalingSSIM(11),r.Results.UpscalingSSIM(12));
Method = r.Results.DemultiplexingMethod(1) + " + " + r.Results.UpscalingMethod(1);

for m = 1:length(MethodList)
    if Method  == MethodList(m)
      FullResult{m+1,1}=Method;
      ms = m;
    end
           
end

switch r.Results.Resolution(1)
    
    case "512×512×32"
       FullResult{ms+1,2} =  Metric;
    case "1024×1024×128"
      FullResult{ms+1,3}   = Metric;
        
    case "2048×2048×512"
      FullResult{ms+1,4}   = Metric;
    end


end  
disp(FullResult)