#!/bin/bash

# ================= 配置區域 =================
# Checkpoint 存放路徑
CP_DIR="$HOME/Documents/ardupilot_criu_checkpoint"

# 日誌文件名
DUMP_LOG="dump.log"
RESTORE_LOG="restore.log"
# ===========================================

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== ArduPilot CRIU 自動熱備份程序 ===${NC}"

# 1. 自動尋找 PID
# ---------------------------------------------
# -n: 最新的一個, -f: 匹配完整命令行 (避免抓到編輯器或grep自己)
# 這裡假設 binary 名字包含 'arducopter' 或 'arduplane'
TARGET_PID=$(pgrep -n -f "arducopter|arduplane")

if [ -z "$TARGET_PID" ]; then
    echo -e "${RED}[錯誤] 找不到正在運行的 ArduPilot 進程！${NC}"
    echo "請確認模擬器已經啟動。"
    exit 1
fi

echo -e "${GREEN}[1/3] 鎖定目標 PID: ${YELLOW}$TARGET_PID${NC}"


# 2. 初始化目錄 & 執行 Dump (存檔)
# ---------------------------------------------
echo -e "${GREEN}[2/3] 正在執行狀態凍結 (Checkpointing)...${NC}"

# 確保目錄存在且乾淨
if [ -d "$CP_DIR" ]; then
    rm -rf "$CP_DIR"
fi
mkdir -p "$CP_DIR"

# 執行 Dump
# 注意：Dump 成功後，原進程會被 Kill，這是正常現象
sudo criu dump \
    -t "$TARGET_PID" \
    -D "$CP_DIR" \
    --shell-job \
    --tcp-established \
    -j -v4 -o "$DUMP_LOG"

# 檢查 Dump 結果
if [ $? -ne 0 ]; then
    echo -e "${RED}[失敗] Dump 失敗！請檢查日誌：$CP_DIR/$DUMP_LOG${NC}"
    exit 1
else
    echo -e "${GREEN}      狀態已保存至磁碟。原進程已暫停。${NC}"
fi


# 3. 馬上執行 Restore (復活)
# ---------------------------------------------
echo -e "${GREEN}[3/3] 正在恢復執行 (Resuming)...${NC}"

# 這裡稍微停 0.5 秒，是為了讓演示時能看清「它真的停了一下」
# 如果你追求極致速度，可以把下面這行 sleep 註解掉
sleep 0.5

# 執行 Restore
# 注意：這裡不加 -d，所以 ArduPilot 會直接接管這個終端機
sudo criu restore \
    -D "$CP_DIR" \
    --shell-job \
    --tcp-established \
    -j -v4 -o "$RESTORE_LOG"

# 注意：如果 Restore 成功，腳本執行流會被 ArduPilot 取代，
# 下面的代碼基本上不會被執行到，除非 Restore 失敗。

if [ $? -ne 0 ]; then
    echo -e "${RED}[失敗] Restore 失敗！請檢查日誌：$CP_DIR/$RESTORE_LOG${NC}"
    exit 1
fi
