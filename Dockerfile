# Base image met CUDA support
FROM nvidia/cuda:12.1.0-base-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Install ComfyUI requirements
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
RUN pip3 install --no-cache-dir -r /workspace/ComfyUI/requirements.txt

# Install RunPod SDK
COPY requirements.txt /workspace/requirements.txt
RUN pip3 install --no-cache-dir -r /workspace/requirements.txt

# Copy workflow and handler
COPY workflow_api.json /workspace/workflow_api.json
COPY handler.py /workspace/handler.py

# Create startup script that uses Network Volume
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Check if network volume is mounted\n\
if [ ! -d "/runpod-volume" ]; then\n\
    echo "ERROR: Network volume not mounted at /runpod-volume"\n\
    exit 1\n\
fi\n\
\n\
echo "Network volume found!"\n\
\n\
# Create symlinks to use models from network volume\n\
mkdir -p /workspace/ComfyUI/models/checkpoints\n\
\n\
# Link models directory from network volume\n\
if [ -d "/runpod-volume/models" ]; then\n\
    rm -rf /workspace/ComfyUI/models\n\
    ln -sf /runpod-volume/models /workspace/ComfyUI/models\n\
    echo "Linked models from network volume"\n\
else\n\
    echo "WARNING: /runpod-volume/models not found"\n\
fi\n\
\n\
# Start ComfyUI in background with fixed host settings\n\
echo "Starting ComfyUI..."\n\
cd /workspace/ComfyUI\n\
python3 main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch &\n\
COMFY_PID=$!\n\
\n\
# Wait for ComfyUI to start\n\
echo "Waiting for ComfyUI to start..."\n\
for i in {1..60}; do\n\
    if curl -s http://127.0.0.1:8188 > /dev/null 2>&1; then\n\
        echo "ComfyUI is ready!"\n\
        break\n\
    fi\n\
    if [ $i -eq 60 ]; then\n\
        echo "ERROR: ComfyUI failed to start"\n\
        exit 1\n\
    fi\n\
    sleep 2\n\
done\n\
\n\
# Start RunPod handler\n\
echo "Starting RunPod handler..."\n\
cd /workspace\n\
python3 handler.py\n\
' > /workspace/start.sh && chmod +x /workspace/start.sh

# Expose port (for testing)
EXPOSE 8188

# Start everything
CMD ["/workspace/start.sh"]
