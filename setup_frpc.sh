#!/bin/bash
# ============================================================
# mmpOS 装 frpc 客户端（连到蔡哥 frps 服务器，暴露 SSH）
#
# 用法：
#   sudo bash setup_frpc.sh          # 安装（下载 frpc + 配置 + systemd 自启）
#   sudo bash setup_frpc.sh off      # 卸载
#
# 装好后，本机 SSH 可通过公网访问：
#   ssh -p 62222 <本机SSH用户>@103.143.81.234
# ============================================================
set -u

FRP_VER="0.51.3"
FRP_DIR="/opt/frp"
FRP_BIN="$FRP_DIR/frpc"
FRP_INI="$FRP_DIR/frpc.ini"
SRV="/etc/systemd/system/frpc.service"

SERVER_ADDR="103.143.81.234"
SERVER_PORT="8055"
TOKEN="4ccba2783eaa4840fd431c37c55ecd8c"
REMOTE_PORT="62222"

URL1="https://gh-proxy.com/https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz"
URL2="https://ghfast.top/https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz"
URL3="https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz"

# ---------- 卸载 ----------
if [ "${1:-}" = "off" ]; then
    echo "== 卸载 frpc =="
    sudo systemctl disable frpc 2>/dev/null
    sudo systemctl stop frpc 2>/dev/null
    sudo rm -f "$SRV"
    sudo rm -rf "$FRP_DIR"
    sudo systemctl daemon-reload
    echo "已卸载"
    exit 0
fi

# ---------- 1. 下载 frpc ----------
if [ ! -x "$FRP_BIN" ]; then
    echo "== 下载 frpc $FRP_VER =="
    sudo mkdir -p "$FRP_DIR"
    cd "$FRP_DIR"
    ok=0
    for url in "$URL1" "$URL2" "$URL3"; do
        echo "  尝试: $url"
        if curl -sL --max-time 180 -o /tmp/frp.tgz "$url" 2>/dev/null \
            && tar xzf /tmp/frp.tgz --strip-components=1 2>/dev/null \
            && [ -x "$FRP_BIN" ]; then
            ok=1
            break
        fi
    done
    rm -f /tmp/frp.tgz
    if [ "$ok" != "1" ]; then
        echo "下载失败，请检查网络"
        exit 1
    fi
fi

# ---------- 2. 写配置 ----------
echo "== 写配置 =="
sudo tee "$FRP_INI" >/dev/null <<EOF
[common]
server_addr = $SERVER_ADDR
server_port = $SERVER_PORT
token = $TOKEN

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = $REMOTE_PORT
EOF

# ---------- 3. systemd 服务 ----------
echo "== 注册 systemd 服务（开机自启）=="
sudo tee "$SRV" >/dev/null <<'EOF'
[Unit]
Description=frp client
After=network.target

[Service]
ExecStart=/opt/frp/frpc -c /opt/frp/frpc.ini
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frpc
sudo systemctl restart frpc

# ---------- 4. 验证 ----------
sleep 2
echo ""
echo "== 状态 =="
sudo systemctl is-active frpc
echo ""
sudo systemctl status frpc --no-pager | head -12
echo ""
echo "如果上面显示 active，说明已经连上。"
echo "远程访问本机：ssh -p $REMOTE_PORT <本机SSH用户>@$SERVER_ADDR"
