# Manual Build Guide
This document outlines the steps to manually build the ArduPilot + Gazebo Docker image from the [Dockerfile](../Dockerfile).

## Prerequisites
Before you begin, ensure you have the following installed on your host machine:

* **Docker Engine**

* **Git**

## 1. Prepare the Environment
First, clone the repository to your local machine and enter the directory:

```bash
git clone cd CPS-Recovery---ArduPilot
```

> **Note:** Ensure you are in the directory containing the ```Dockerfile```.

## 2. Build the Docker Image
Run the following command to build the image.

```bash
docker build -t ardupilot-criu-gui:local .
```

### Explanation

* ```-t ardupilot-criu-gui:local```: Tags the image with a name and version.

* ```.```: Specifies that the Dockerfile is in the current directory.

Depending on your internet connection and computer speed, this process may take 10-30 minutes.

## 3. Verify the Build
Once the build is complete, verify that the image exists:

```bash
docker images
```

You should see ```ardupilot-criu-gui``` with tag ```local``` in the list.

## 4. Running the Local Image
If you built the image locally instead of pulling from Docker Hub, run the following command:

```bash
docker run -it --privileged --net=host --gpus all \
  --env="DISPLAY=$DISPLAY" \
  --env="NVIDIA_VISIBLE_DEVICES=all" \
  --env="NVIDIA_DRIVER_CAPABILITIES=all" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --name ardupilot \
  ardupilot-criu-gui:local /bin/bash
```