EDSR_path = "./tools/methods/EDSR-PyTorch-master/";
EDSR_testpath = EDSR_path + "test/";
EDSR_models   = EDSR_path + "models/";
EDSR_reconpath = EDSR_path + "experiment/test/results-Demo/";
switch EDSR_SR
    case 2
    model_name = "edsr_baseline_x2-1bc95232.pt";
    scl = 2;
    case 3
    model_name = "edsr_baseline_x3-abf2a44e.pt";
    scl = 3;
    case 4
    model_name = "edsr_baseline_x4-6b446fab.pt";
    scl = 4;
    case 8
    model_name = "edsr_baseline_x4-6b446fab.pt"; 
    scl = 4;
end
    
execEDSR = "python " + EDSR_path + "src/main.py --data_test Demo --pre_train "...
    + EDSR_models + model_name + " --scale " + string(num2str(scl)) ...
    + " --test_only --save_results";
