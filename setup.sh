#!/bin/bash

# ==============================================================================
# SCRIPT CHUẨN HÓA MÔI TRƯỜNG
# Thành phần: CockroachDB v23.1.10, Redis Server, Java JRE (cho Kafka CDC)
# Hỗ trợ: Windows WSL2 (Ubuntu) & macOS (Intel/M1/M2)
# ==============================================================================

set -e # Dừng script nếu có lỗi

# Màu sắc hiển thị
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Đang bắt đầu chuẩn hóa hệ thống (M.Sc Level) ===${NC}"

# 1. Nhận diện hệ điều hành và Kiến trúc
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "Hệ điều hành: ${GREEN}$OS${NC} | Kiến trúc: ${GREEN}$ARCH${NC}"

# 2. Cài đặt các gói phụ thuộc (Dependencies)
echo -e "${BLUE}[1/5] Đang cài đặt Dependencies (Redis, Java, Net-tools)...${NC}"
if [ "$OS" == "Linux" ]; then
    sudo apt update
    sudo apt install -y curl wget tar redis-server default-jre net-tools iputils-ping ufw
elif [ "$OS" == "Darwin" ]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Lỗi: Chưa cài Homebrew. Hãy cài tại https://brew.sh/ trước.${NC}"
        exit 1
    fi
    brew install redis openjdk
else
    echo -e "${RED}Hệ điều hành không hỗ trợ.${NC}"
    exit 1
fi

# 3. Tải và cài đặt CockroachDB v23.1.10
echo -e "${BLUE}[2/5] Đang cài đặt CockroachDB v23.1.10...${NC}"
if [ "$OS" == "Linux" ]; then
    URL="https://binaries.cockroachdb.com/cockroach-v23.1.10.linux-amd64.tgz"
elif [ "$OS" == "Darwin" ]; then
    if [ "$ARCH" == "arm64" ]; then
        URL="https://binaries.cockroachdb.com/cockroach-v23.1.10.darwin-11.0-arm64.tgz"
    else
        URL="https://binaries.cockroachdb.com/cockroach-v23.1.10.darwin-10.9-amd64.tgz"
    fi
fi

wget -qO- $URL | tar -xvz
sudo cp -i cockroach-v23.1.10.*/cockroach /usr/local/bin/
rm -rf cockroach-v23.1.10.*

# 4. Cấu hình Redis (Cho phép kết nối từ VPN)
echo -e "${BLUE}[3/5] Đang cấu hình Redis Server...${NC}"
REDIS_CONF=""
[ "$OS" == "Linux" ] && REDIS_CONF="/etc/redis/redis.conf"
[ "$OS" == "Darwin" ] && [ "$ARCH" == "arm64" ] && REDIS_CONF="/opt/homebrew/etc/redis.conf"
[ "$OS" == "Darwin" ] && [ "$ARCH" == "x86_64" ] && REDIS_CONF="/usr/local/etc/redis.conf"

if [ -f "$REDIS_CONF" ]; then
    sudo sed -i 's/bind 127.0.0.1 ::1/bind 0.0.0.0/g' $REDIS_CONF || true
    sudo sed -i 's/protected-mode yes/protected-mode no/g' $REDIS_CONF || true
    echo -e "Đã cập nhật $REDIS_CONF"
fi

# 5. Tạo cấu trúc thư mục chứng chỉ (Secure Mode)
echo -e "${BLUE}[4/5] Khởi tạo thư mục Security (TLS)...${NC}"
mkdir -p ~/certs ~/safe_dir
chmod 700 ~/safe_dir

# 6. Thiết lập Hostname (Tùy chọn)
echo -e "${BLUE}[5/5] Cấu hình định danh Node...${NC}"
read -p "Nhập ID Node của bạn (ví dụ: node1): " node_id
if [ "$OS" == "Linux" ]; then
    sudo hostnamectl set-hostname $node_id || echo "Không thể đổi hostname tự động."
fi

echo -e "${GREEN}=== HOÀN TẤT CHUẨN HÓA ===${NC}"
echo -e "Phiên bản CockroachDB: $(cockroach version | grep 'Build Tag' | awk '{print $3}')"
echo -e "Trạng thái Redis: Đã sẵn sàng (bind 0.0.0.0)"
echo -e "Java: $(java -version 2>&1 | head -n 1)"
echo -e "${RED}LƯU Ý: Hãy gửi IP VPN của bạn cho Trưởng nhóm (Khoa) để tổng hợp file /etc/hosts.${NC}"