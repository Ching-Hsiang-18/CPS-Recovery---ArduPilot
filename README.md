# ArduPilot + Gazebo Harmonic + CRIU Docker Environment

This repository provides a fully integrated Docker environment for **ArduPilot SITL** and **Gazebo Harmonic**, featuring **CRIU** (Checkpoint/Restore In Userspace) support.

<!-- **Key Features:**

* **Fixes & Optimizations:** Solved `MAVProxy` path issues, environment variable conflicts, and permission errors.
* **GUI Support:** Full 3D rendering support for Gazebo using host GPU passthrough.
* **Manual Control:** Full control over simulation parameters and startup sequence. -->

This README provides a guide to launch the container and start a simple simulation. See [Recovery Demo](doc/recovery_demo.md) for how to run a CRIU-based recovery demo.

---

## 1. Get the Image

Pull the pre-built image from Docker Hub:

```bash
docker pull camel180/ardupilot-criu-gui:latest
```

> **Note:** If you intend to build the image locally using the Dockerfile, please refer to the [Manual Build Guide](doc/manual_build.md).

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
  --name ardupilot \
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
docker exec -it ardupilot /bin/bash
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

## 3. Basic Control Commands & Stopping

### MAVLink Commands
Perform these commands in **Terminal B (MAVProxy)** to control the drone:

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

### Stopping the Simulation
To fully stop the simulation, you must stop the processes in **both terminals:**

1. **Terminal B (ArduPilot):** Press ```Ctrl+C``` to stop the flight controller.
2. **Terminal A (Gazebo):** Press ```Ctrl+C``` to stop the physics engine.


---

## 4. Exiting, Restarting, and Cleanup

### Leaving the Container

To log out of the container shell and return to your host terminal, simply type:

```bash
exit
```

> **Note:** If you exit from **Terminal A**, the container will stop running.

### Restarting an Existing Container

If you have exited the container and it has stopped, you don't need to run ```docker run``` command again. You can simply start the existing one:

1. **Start the background container:**

```bash
docker start ardupilot
```

2. **Enter the container again:**

```bash
docker exec -it ardupilot /bin/bash
```

### Removing the Container

If you want to delete the container completely (e.g., to start fresh with a new ```docker run``` command), use:

```bash
docker rm -f ardupilot
```
