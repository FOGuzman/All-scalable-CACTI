VSRpp_path = "./tools/methods/BasicVSR_PlusPlus/";
VSRpp_testpath = VSRpp_path + "data/in/";
VSRpp_reconpath = VSRpp_path + "results/out/";
    
execVSRpp = "python " + "./tools/methods/BasicVSR_PlusPlus/demo/restoration_video_demo.py " +...
    "./tools/methods/BasicVSR_PlusPlus/configs/basicvsr_plusplus_reds4.py " + ...
    "./tools/methods/BasicVSR_PlusPlus/weigths/basicvsr_plusplus_reds4.pth " + ...
    "./tools/methods/BasicVSR_PlusPlus/data/in ./tools/methods/BasicVSR_PlusPlus/results/out/";