# ArduPilot + Gazebo Harmonic + CRIU Docker Environment

This repository provides a fully integrated Docker environment for **ArduPilot SITL** and **Gazebo Harmonic**, featuring **CRIU** (Checkpoint/Restore In Userspace) support.

**Key Features:**

* **Fixes & Optimizations:** Solved `MAVProxy` path issues, environment variable conflicts, and permission errors.
* **GUI Support:** Full 3D rendering support for Gazebo using host GPU passthrough.
* **Manual Control:** Full control over simulation parameters and startup sequence.

---

## 1. Get the Image

Pull the pre-built image from Docker Hub:

```bash
docker pull camel180/ardupilot-criu-gui:latest
```

> **Note:** If you just built the image locally with the tag `ardupilot-criu-gui:v4`, you can skip this step.

---

## 2. Running the Simulation

To run a complete simulation with both the 3D physics engine (Gazebo) and the Flight Controller (ArduPilot), you need to open **two terminal windows**.

### Terminal A: Start Container & Gazebo

This terminal will host the Docker container and display the 3D simulation window.

1. **Grant X11 Display Permissions** (Required for GUI):
```bash
xhost +
```


2. **Start the Container:**
```bash
docker run -it --privileged --net=host --gpus all \
  --env="DISPLAY=$DISPLAY" \
  --env="NVIDIA_VISIBLE_DEVICES=all" \
  --env="NVIDIA_DRIVER_CAPABILITIES=all" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --name ardupilot_v4 \
  camel180/ardupilot-criu-gui:latest /bin/bash
```


3. **Launch Gazebo:**
Inside the container, run:
```bash
gz sim -v4 -r iris_runway.sdf
```


*You should see the Gazebo window appear with an Iris drone on the runway.*

---

### Terminal B: Start ArduPilot (SITL)

Keep Terminal A open. Open a **new terminal window** on your host machine to connect to the Flight Controller.

1. **Enter the Running Container:**
```bash
docker exec -it ardupilot_v4 /bin/bash
```


2. **Start ArduPilot SITL:**
Run the standard vehicle simulation script:
```bash
sim_vehicle.py -v ArduCopter -f JSON --console
```


3. **Set Frame Parameters (Required):**
Once MAVProxy starts (you will see the `MAV>` prompt), **you must manually set the frame class and type** for the simulation to work correctly:
```bash
param set FRAME_CLASS 1
param set FRAME_TYPE 1
```



---

## 3. Basic Control Commands

After setting the parameters above, you can use the following commands in the MAVProxy console to test the drone:

* **Switch Mode:**
```bash
mode guided
```


* **Arm Throttle:**
```bash
arm throttle
```


* **Takeoff:**
```bash
takeoff 10
```



---

## 4. Stopping and Restarting

* **To Stop:** Press `Ctrl+C` in the terminals or type `exit`.
* **To Cleanup:** Before running `docker run` again, ensure you remove the old container:
```bash
docker rm -f ardupilot_v4
```