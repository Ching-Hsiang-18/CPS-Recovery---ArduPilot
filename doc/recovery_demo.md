# Snapshot & Recovery Demo Guide

This guide details the manual steps required to run the specific **Snapshot Recovery Demo**. This process involves running the simulation components manually in separate terminals to allow for the external recovery script to function correctly.

## Prerequisites

1. Ensure the Docker container is running (see the main [README](../README.md)).
2. Ensure you have **4 terminal windows**, all inside the same Docker container.

---

## Step 1: Start the Simulation Components

You need to attach to the **same** running container in **four** separate terminals by:

```bash
docker exec -it ardupilot /bin/bash
```

### Terminal 1: Gazebo (Physics Engine)

**Role:** Renders the 3D environment.

**Command:**

```bash
gz sim -v4 -r iris_runway.sdf
```

*(The Gazebo GUI should appear.)*

---

### Terminal 2: ArduCopter (Flight Controller)

**Role:** The core flight control software (SITL).

**Command:**

```bash
/home/ardupilot/ardupilot/build/sitl/bin/arducopter --model JSON --speedup 1 --slave 0 --sim-address=127.0.0.1 -I0 -w --defaults /home/ardupilot/ardupilot/Tools/autotest/default_params/copter.parm
```

*(This should hang on, "waiting for connection ....")*

---

### Terminal 3: MAVProxy (Ground Control)

**Role:** Connects to the flight controller via TCP.

**Command:**

```bash
mavproxy.py --master tcp:127.0.0.1:5760
```

Once connected, this would be the terminal where you enter all the mavlink control commands.

---

## Step 2: Launch the Drone

Launch the drone by configuring and commanding in the **MAVProxy terminal**: 

### A. Configure Parameters

```bash
param set FRAME_CLASS 1
param set FRAME_TYPE 1
```

### B. Swtich Mode

```bash
mode guided
```

### C. Arm Throttle

```bash
arm throttle
```

### D. Takeoff

```bash
takeoff 5 // Takeoff to the altitude of 5 meters
```

---

## Step 3: Run the Recovery Demo

Now that the simulation is fully running, in the **fourth terminal** (within the same container), run the snapshot-recovery script:

```bash
sudo ./snapshot_recovery_demo.sh
```
