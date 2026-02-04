# 基於 Ubuntu 22.04
FROM ubuntu:22.04

# 1. 全域設定：解決時區與互動式卡住的問題
# 設定全域變數，讓所有後續指令預設都不跳出對話框
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 先設定好時區，這是最容易卡住的地方
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# 2. 安裝基礎工具、CRIU 依賴 + [修正] uuid-dev/asciidoc + GUI 修復包
# 這裡再次強調 DEBIAN_FRONTEND=noninteractive，確保 asciidoc 不會彈窗
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git build-essential pkg-config python3-pip sudo wget nano curl lsb-release gnupg \
    vim \
    cmake \
    # CRIU 依賴 (補全 uuid-dev 與 asciidoc)
    libprotobuf-dev libprotobuf-c-dev protobuf-c-compiler protobuf-compiler \
    python3-protobuf libnl-3-dev libnet-dev libcap-dev libaio-dev \
    libgnutls28-dev libnftables-dev libbsd-dev uuid-dev asciidoc \
    # GUI 圖形介面與 Qt 依賴 (解決 Gazebo 黑屏/崩潰)
    x11-apps mesa-utils \
    libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-randr0 libxcb-render-util0 libxcb-xinerama0 libxcb-xfixes0 \
    libxkbcommon-x11-0 libgl1-mesa-glx libxcb-cursor0 libxcb-util1 \
    libcanberra-gtk-module libcanberra-gtk3-module \
    # 其他常用庫
    rapidjson-dev libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. 安裝 Gazebo Harmonic (官方源，版本 v8)
RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    apt-get update && \
    apt-get install -y gz-harmonic libgz-sim8-dev && \
    rm -rf /var/lib/apt/lists/*

# 4. 建立使用者 ardupilot
RUN useradd -m -s /bin/bash ardupilot && \
    usermod -aG sudo ardupilot && \
    echo "ardupilot ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. 編譯並安裝 CRIU (使用 make install)
WORKDIR /tmp
RUN git clone --branch v4.2 https://github.com/checkpoint-restore/criu.git && \
    cd criu && make -j$(nproc) && make install && cd .. && rm -rf criu

# ================= 轉換身分：接下來都是普通使用者操作 =================
USER ardupilot
ENV USER=ardupilot
WORKDIR /home/ardupilot

# 6. 下載 ArduPilot 原始碼
RUN git clone --recursive https://github.com/ArduPilot/ardupilot.git

# 7. 安裝 ArduPilot 開發環境依賴
WORKDIR /home/ardupilot/ardupilot
RUN Tools/environment_install/install-prereqs-ubuntu.sh -y

# 8. 下載並編譯 ArduPilot-Gazebo 插件 (適配 Gazebo Harmonic)
WORKDIR /home/ardupilot
RUN git clone https://github.com/ArduPilot/ardupilot_gazebo.git && \
    cd ardupilot_gazebo && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc)

# 9. 設定環境變數 (NVIDIA 直通 + Qt 修復 + ArduPilot 路徑)
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV QT_X11_NO_MITSHM=1

RUN echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}' >> ~/.bashrc && \
    echo 'export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}' >> ~/.bashrc && \
    echo 'export PATH=$PATH:$HOME/ardupilot/Tools/autotest' >> ~/.bashrc && \
    echo 'export PATH=$PATH:$HOME/ardupilot/Tools/scripts' >> ~/.bashrc && \
    echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc

CMD ["/bin/bash"]
