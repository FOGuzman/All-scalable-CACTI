# All-scalable-CACTI
Official code for the paper
“Scalable Coding for High-Resolution, High-Compression Ratio Snapshot Compressive Video”
Felipe O. Guzman, et al.

This repository contains all of the MATLAB and Python tools used to generate the experiments, reconstructions, and figures presented in the paper.

## 🛠️ Installation

1. **Clone this repository**  

```bash
   git clone https://github.com/FOGuzman/All-scalable-CACTI.git
   cd All-scalable-CACTI
````

2. **Setup MATLAB**

   * Ensure your MATLAB path includes this repository root.
   * *(Optional)* If you use the MATLAB Engine API for Python, point it to your MATLAB installation.

3. **Setup Python (if using `tools/`)**

   * **Primary environment:**

     ```bash
     conda env create -f env.yml
     conda activate all-scalable-cacti
     ```
   * **Alternate environment:**

     ```bash
     conda env create -f env2.yml
     conda activate all-scalable-cacti-alt
     ```
   * **Install additional dependencies:**

     ```bash
     pip install -r tools/requirements.txt
     ```

## ▶️ Usage

### MATLAB pipeline

* **Generate ground-truth data**

  ```matlab
  run main_gt.m
  ```

  Synthesizes the high-resolution video frames used as “ground truth.”

* **Run full scalable CACTI reconstruction**

  ```matlab
  run main_all.m
  ```

  Performs snapshot compressive capture simulation, demultiplexing (GAP-TV, DeSCI, …), and upscaling (2DI, 3DI, EDSR, VSR++).

* **Plug-and-play grayscale reconstruction**

  ```matlab
  run main_PnP_gray.m
  ```

#### Comparisons & Metrics

* **Upscaling comparator:**

  ```matlab
  run main_PnP_gray_comparator_UP.m
  ```
* **Reconstruction order comparator:**

  ```matlab
  run main_PnP_gray_comparator_order.m
  ```
* **Temporal quality metrics:**

  ```matlab
  run main_temporal_metric.m
  ```
* **Figure generation:**

  ```matlab
  run createFig_supp_and_expresult.m
  ```

  Produces all figures for the paper’s main text and supplementary material.

### Python helper tools

Inside the `tools/` folder you’ll find Python scripts for data pre-/post-processing, visualization, and optional GPU acceleration. After activating your conda environment:

```bash
cd tools
python data_loader.py       # e.g. prepares measurement tensors
python visualize_results.py
```

## 📝 Citation

If you use this code in your research, please cite:

```bibtex
@article{guzman2025scalable,
  title={Scalable Coding for High-Resolution, High-Compression Ratio Snapshot Compressive Video},
  author={Guzm{\'a}n, Felipe and D{\'\i}az, Nelson and Romero, Bastian and Vera, Esteban},
  journal={IEEE Transactions on Image Processing},
  year={2025},
  publisher={IEEE}
}
```

## 📬 Contact

**Felipe Guzman**

* Email: [felipe.guzman@pucv.cl](mailto:felipe.guzman@pucv.cl)
* GitHub: [@FOGuzman](https://github.com/FOGuzman)

```
```

