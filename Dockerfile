# 1) Specify Python version and define build stage
# ----------------------------------------------------------
    ARG PYTHON="3.8.17"
    FROM python:${PYTHON}-slim as build
  
    # ----------------------------------------------------------
    # 2) Define arguments you use later
    # ----------------------------------------------------------
    ARG PYTORCH=1.11.0
    ARG TORCHVISION=0.12.0
    ARG MMCV="1.5.0"
    ARG MMDET="2.19.0"
    ENV PYTHONUNBUFFERED 1
  
    # ----------------------------------------------------------
    # 3) Create working directory & some folders
    # ----------------------------------------------------------
    WORKDIR /usr/swin
    RUN mkdir -p data predictions results result_dir_prefix
  
    # ----------------------------------------------------------
    # 4) Install system-level dependencies
    # ----------------------------------------------------------
    RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates \
        g++ \
        git \
        openssh-client \
        ffmpeg \
        libsm6 \
        libxext6 \
        libjpeg-dev \
        zlib1g-dev \
        libpng-dev \
        && rm -rf /var/lib/apt/lists/*
  
    # ----------------------------------------------------------
    # 5) Install Python dependencies
    # ----------------------------------------------------------
    RUN pip install --no-cache-dir \
        torch==${PYTORCH} \
        torchvision==${TORCHVISION} \
        --extra-index-url https://download.pytorch.org/whl/cpu
  
    COPY requirements.txt requirements.txt
    RUN pip install -r requirements.txt
  
    RUN pip install --no-cache-dir mmcv-full==${MMCV}
    RUN pip install -U scikit-learn boto3 openmim && mim install mmengine && pip install mmdet==${MMDET}
    RUN pip install --no-cache-dir --upgrade numpy
  
    # ----------------------------------------------------------
    # 6) Clone and install mmdetection
    # ----------------------------------------------------------
    RUN git clone https://github.com/open-mmlab/mmdetection.git
    RUN /bin/bash -c "\
        cd mmdetection && \
        git checkout tags/v${MMDET} -b 2.x && \
        pip install -v -e ."
  
    # ----------------------------------------------------------
    # 7) Add source files
    # ----------------------------------------------------------
    WORKDIR /usr/src/app
    COPY src/ /usr/src/app/
    COPY src/configs/swin-sim-seg/1_mask_rcnn_swin-t-p4-w7_fpn_ms-crop-3x_sim_seg.py /usr/src/app/configs/swin-sim-seg/
    RUN ls -ltr /usr/src/app/configs/swin-sim-seg/
   
    RUN ls -ltr /usr/src/app/  # Debugging: Verify files are present
   
  
   
   # ----------------------------------------------------------
   # 8) Define entrypoint
   # ----------------------------------------------------------
    EXPOSE 8080
    CMD ["python3", "1_run_python.py"]




# # ----------------------------------------------------------
#     ARG PYTHON="3.8.17"
#     FROM python:${PYTHON}-slim as build
    
#     # ----------------------------------------------------------
#     # 2) Define arguments you use later
#     # ----------------------------------------------------------
#     ARG PYTORCH=1.11.0
#     ARG TORCHVISION=0.12.0
#     ARG MMCV="1.5.0"
#     ARG MMDET="2.19.0"
#     ENV PYTHONUNBUFFERED 1
    
#     # ----------------------------------------------------------
#     # 3) Create working directory & some folders
#     # ----------------------------------------------------------
#     WORKDIR /usr/swin
#     RUN mkdir -p data predictions results result_dir_prefix
    
#     # ----------------------------------------------------------
#     # 4) Install system-level dependencies
#     # ----------------------------------------------------------
#     RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
#         ca-certificates \
#         g++ \
#         git \
#         openssh-client \
#         ffmpeg \
#         libsm6 \
#         libxext6 \
#         libjpeg-dev \
#         zlib1g-dev \
#         libpng-dev \
#         && rm -rf /var/lib/apt/lists/*
    
#     # ----------------------------------------------------------
#     # 5) Install Python dependencies
#     # ----------------------------------------------------------
#     RUN pip install --no-cache-dir \
#         torch==${PYTORCH} \
#         torchvision==${TORCHVISION} \
#         --extra-index-url https://download.pytorch.org/whl/cpu
    
#     COPY requirements.txt requirements.txt
#     RUN pip install -r requirements.txt
    
#     RUN pip install --no-cache-dir mmcv-full==${MMCV}
#     RUN pip install -U scikit-learn boto3 openmim && mim install mmengine && pip install mmdet==${MMDET}
#     RUN pip install --no-cache-dir --upgrade numpy
    
#     # ----------------------------------------------------------
#     # 6) Clone and install mmdetection
#     # ----------------------------------------------------------
#     RUN git clone https://github.com/open-mmlab/mmdetection.git
#     RUN /bin/bash -c "\
#         cd mmdetection && \
#         git checkout tags/v${MMDET} -b 2.x && \
#         pip install -v -e ."
    
#     # ----------------------------------------------------------
#     # 7) Add source files
#     # ----------------------------------------------------------
#     WORKDIR /usr/src/app
#     COPY src/ /usr/src/app/
#     COPY src/configs/swin-sim-seg/1_mask_rcnn_swin-t-p4-w7_fpn_ms-crop-3x_sim_seg.py /usr/src/app/configs/swin-sim-seg/
#     RUN ls -ltr /usr/src/app/configs/swin-sim-seg/
    
#     RUN ls -ltr /usr/src/app/  # Debugging: Verify files are present
    
    
#     # ----------------------------------------------------------
#     # 8) Define entrypoint
#     # ----------------------------------------------------------
#     ENTRYPOINT ["python3", "-m", "awslambdaric"]
#     CMD ["handler.lambda_handler"]