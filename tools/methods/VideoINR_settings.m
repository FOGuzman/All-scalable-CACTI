VINR_path = "./tools/methods/VideoINR-Continuous-Space-Time-Super-Resolution-main/";
VINR_testpath = VINR_path + "test/";
VINR_models   = VINR_path + "checkpoint/latest_G.pth";
VINR_reconpath = VINR_path + "experiment/test/";

    
execVINR = "python " + VINR_path + "demo.py --space_scale" + spix + " --time_scale 1 --data_path "...
    + VINR_testpath + " --model_path" + VINR_models + " ----out_path_ours " + VINR_reconpath;
