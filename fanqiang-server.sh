#!/bin/bash
# ============================================================
# 翻墙【服务器端】脚本 — 软路由/服务器提供 26779 HTTP + 1081 socks 代理
# 支持 OpenWrt 和 Ubuntu（x86_64 / arm64）
#
# 功能：装 xray，开 26779(HTTP) + 1081(socks) 代理端口，
#       转发到你自己的机场节点（vless/vmess）。
#
# ============ 一键运行 ============
#   ./fanqiang-server.sh "vless://UUID@节点地址:端口?..." 
#   或
#   ./fanqiang-server.sh "vmess://..."
#
# ============ 使用说明 ============
# 1. 把机场订阅里的某个节点链接复制出来（vless:// 或 vmess:// 开头）
# 2. 本机运行：bash fanqiang-server.sh "节点链接"
# 3. 跑完就开好 26779(HTTP) + 1081(socks) 两个代理端口
# 4. 矿机侧用客户端脚本连过来：fanqiang-client.sh <本机IP>:26779
#
# 取消：bash fanqiang-server.sh stop
# ============================================================
set -u

NODE="${1:-}"

# ---------- 停止 ----------
if [ "$NODE" = "stop" ]; then
    echo "== 停止翻墙服务端 =="
    sudo pkill -f xray 2>/dev/null || pkill -f xray 2>/dev/null
    echo "已停止 xray"
    exit 0
fi

if [ -z "$NODE" ]; then
    echo "用法: $0 \"<vless://或vmess://节点链接>\""
    echo "示例: $0 \"vless://abc-123@hk.example.com:443?type=tls\""
    exit 1
fi

# ---------- 1. 检测系统架构 ----------
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) XRAY_ARCH="amd64" ;;
    aarch64) XRAY_ARCH="arm64" ;;
    *) echo "不支持的架构: $ARCH"; exit 1 ;;
esac

# 检测是 OpenWrt 还是 Ubuntu（影响下载工具和路径）
OS_TYPE="ubuntu"
[ -f /etc/openwrt_release ] && OS_TYPE="openwrt"
echo "== 系统: $OS_TYPE / $ARCH =="

# ---------- 2. 下载 xray ----------
XRAY_BIN="/usr/local/bin/xray"
if [ ! -x "$XRAY_BIN" ]; then
    echo "下载 xray ..."
    XRAY_URL="https://gh-proxy.com/https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip"
    curl -sL --max-time 120 -o /tmp/xray.zip "$XRAY_URL" || { echo "xray 下载失败"; exit 1; }
    command -v unzip >/dev/null || { echo "需要 unzip，请先安装"; exit 1; }
    unzip -o /tmp/xray.zip -d /tmp/xray_dir >/dev/null 2>&1
    sudo cp /tmp/xray_dir/xray "$XRAY_BIN" 2>/dev/null || cp /tmp/xray_dir/xray "$XRAY_BIN"
    sudo chmod +x "$XRAY_BIN" 2>/dev/null || chmod +x "$XRAY_BIN"
    echo "xray 已安装"
fi

# ---------- 3. 解析节点链接生成 xray 配置 ----------
echo "解析节点链接 ..."
CONF=$(python3 - "$NODE" <<'PYEOF'
import sys, json, base64, urllib.parse

node = sys.argv[1]

outbound = None
if node.startswith("vless://"):
    body = node[len("vless://"):]
    uuid, rest = body.split("@", 1)
    hostport, _, query = rest.partition("?")
    host, _, port = hostport.rpartition(":")
    params = dict(urllib.parse.parse_qsl(query))
    o = {
        "protocol": "vless",
        "settings": {"vnext": [{"address": host, "port": int(port or 443), "users": [{"id": uuid, "encryption": "none", "flow": params.get("flow", "")}]}]},
        "streamSettings": {"network": params.get("type", "tcp")},
        "tag": "proxy"
    }
    if params.get("security") == "tls" or params.get("type") in ("tcp",) and "tls" in params:
        o["streamSettings"]["security"] = "tls"
        o["streamSettings"]["tlsSettings"] = {"serverName": params.get("sni", host), "allowInsecure": True}
    outbound = o
elif node.startswith("vmess://"):
    raw = node[len("vmess://"):]
    try:
        j = json.loads(base64.b64decode(raw + "=" * (-len(raw) % 4)).decode())
    except Exception:
        j = json.loads(base64.b64decode(raw).decode())
    o = {
        "protocol": "vmess",
        "settings": {"vnext": [{"address": j["add"], "port": int(j["port"]), "users": [{"id": j["id"], "security": j.get("scy", "auto"), "alterId": int(j.get("aid", 0))}]}]},
        "streamSettings": {"network": j.get("net", "tcp")},
        "tag": "proxy"
    }
    if j.get("tls") == "tls":
        o["streamSettings"]["security"] = "tls"
        o["streamSettings"]["tlsSettings"] = {"serverName": j.get("sni", j["add"]), "allowInsecure": True}
    outbound = o

if not outbound:
    print("❌ 无法解析节点链接，请确认是 vless:// 或 vmess:// 开头"); sys.exit(1)

cfg = {
    "inbounds": [
        {"port": 26779, "protocol": "http", "listen": "0.0.0.0"},
        {"port": 1081, "protocol": "socks", "listen": "0.0.0.0", "settings": {"udp": True, "auth": "noauth"}}
    ],
    "outbounds": [outbound],
    "routing": {"domainStrategy": "AsIs", "rules": []}
}
print(json.dumps(cfg, ensure_ascii=False, indent=2))
PYEOF
)

if [ $? -ne 0 ] || [ -z "$CONF" ]; then
    echo "节点解析失败"
    exit 1
fi

CONF_DIR="/usr/local/etc/xray"
sudo mkdir -p "$CONF_DIR" 2>/dev/null || mkdir -p "$CONF_DIR"
echo "$CONF" | sudo tee "$CONF_DIR/config.json" >/dev/null 2>&1 || echo "$CONF" > "$CONF_DIR/config.json"
echo "配置已写入 $CONF_DIR/config.json"

# ---------- 4. 启动 xray ----------
if pgrep -x xray >/dev/null 2>&1; then
    sudo pkill -x xray 2>/dev/null
    sleep 1
fi
sudo setsid "$XRAY_BIN" run -c "$CONF_DIR/config.json" >/tmp/xray.log 2>&1 < /dev/null &
sleep 2

# ---------- 5. 验证 ----------
echo ""
echo "== 验证 =="
echo "xray 进程: $(pgrep -x xray | wc -l) 个"
echo "监听端口:"
(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null) | grep -E ':(26779|1081)' | head -2
echo ""
echo "✅ 翻墙服务端已启动："
echo "   HTTP 代理: http://本机IP:26779"
echo "   SOCKS 代理: socks5://本机IP:1081"
echo ""
echo "矿机侧连过来：curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s 本机IP:26779"
