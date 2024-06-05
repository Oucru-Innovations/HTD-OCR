FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Set environment variables to non-interactive to avoid some issues during installation
ENV DEBIAN_FRONTEND noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates git wget sudo \
    cmake ninja-build build-essential ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -a -y

# Set environment variables for conda
ENV PATH=/opt/conda/bin:$PATH

# Create a non-root user
ARG USER_ID=1000
RUN useradd -m --no-log-init --system --uid ${USER_ID} appuser -g sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER appuser
WORKDIR /home/appuser

# Set up conda and create Python 3.10 environment
RUN conda create -n py311 python=3.11 -y
RUN echo "conda activate py311" >> ~/.bashrc
ENV PATH="/opt/conda/envs/py311/bin:$PATH"

# Install PyTorch and dependencies in Python 3.10 environment
RUN pip install --upgrade pip
RUN pip install tensorboard
# RUN pip install torch==2.0.0+cu118 torchvision==0.18.0+cu118 -f https://download.pytorch.org/whl/cu118/torch_stable.html
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install setuptools, packaging, and wheel to avoid pkg_resources import error
RUN pip install setuptools packaging wheel

# Install fvcore and other dependencies
RUN pip install --user 'git+https://github.com/facebookresearch/fvcore' \
    cython pyyaml matplotlib tqdm opencv-python

# Install detectron2
RUN python -m pip install 'git+https://github.com/facebookresearch/detectron2.git'


# Set a fixed model cache directory
ENV FVCORE_CACHE="/tmp"

# Create a working directory for the application
WORKDIR /home/appuser/app

# Copy the current directory contents into the container
COPY . /home/appuser/app

# Copy the transformed requirements.txt to the container
COPY requirements.txt /home/appuser/app/requirements.txt

# Install Python dependencies
RUN pip install --user --no-cache-dir -r requirements.txt

# Install tensorflow
RUN pip install numpy numba llvmlite pillow imantics imutils imgaug prefetch_generator

# Install google drive download
RUN pip install gdown

# Install tensorflow
RUN pip install tensorflow

# RUN pip install tensorflow-estimator

# RUN pip install tensorflow-io-gcs-filesystem

# RUN pip install llvmlite


# Expose the port on which the application will run
EXPOSE 8080
EXPOSE 3000
EXPOSE 5000

# Command to run the pipeline in server mode
CMD ["python3", "main.py", "-op", "Server"]
