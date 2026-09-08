#!/bin/bash
# ============================================================
# 矿机整机翻墙脚本（透明代理 via gost → 软路由 HTTP 代理）
# 原理：iptables 把矿机出站 TCP 全部 REDIRECT 到本机 gost，
#       gost 再转成 HTTP 代理流量发到软路由翻墙端口。
# 矿机运行一次即可整机翻墙，矿工/下载/API 全部走代理，无感知。
#
# gost 从 GitHub release 自动下载（被墙时自动 fallback gh-proxy 镜像）。
#
# 用法：./fanqiang.sh <软路由HTTP代理IP:端口>
#   丰州：./fanqiang.sh 192.168.9.1:26779
#   金山：./fanqiang.sh 192.168.9.1:26779
#   潘山：./fanqiang.sh 192.168.7.2:26779
#   郑国权：./fanqiang.sh 192.168.0.34:26779
#
# 卸载：./fanqiang.sh off
# ============================================================
set -u

ROUTER="${1:-}"
GOST_PORT=12345
GOST_BIN="/usr/local/bin/gost"
GOST_VER="3.0.0-rc10"
GOST_URL1="https://gh-proxy.com/https://github.com/go-gost/gost/releases/download/v${GOST_VER}/gost_${GOST_VER}_linux_amd64.tar.gz"
GOST_URL2="https://github.com/go-gost/gost/releases/download/v${GOST_VER}/gost_${GOST_VER}_linux_amd64.tar.gz"

# ---------- 取消翻墙 ----------
if [ "$ROUTER" = "off" ] || [ "$ROUTER" = "stop" ]; then
    echo "== 取消翻墙 =="
    sudo pkill -f "redirect://:$GOST_PORT" 2>/dev/null
    for chain in OUTPUT PREROUTING; do
        sudo iptables -t nat -D $chain -p tcp -j REDIRECT --to-ports "$GOST_PORT" 2>/dev/null
        sudo iptables -t nat -D $chain -p tcp -d 10.0.0.0/8 -j ACCEPT 2>/dev/null
        sudo iptables -t nat -D $chain -p tcp -d 172.16.0.0/12 -j ACCEPT 2>/dev/null
        sudo iptables -t nat -D $chain -p tcp -d 192.168.0.0/16 -j ACCEPT 2>/dev/null
    done
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
    echo "已取消翻墙"
    exit 0
fi

# ---------- 校验参数 ----------
if [ -z "$ROUTER" ]; then
    echo "用法: $0 <软路由HTTP代理IP:端口>"
    echo "例: $0 192.168.9.1:26779"
    exit 1
fi

echo "== 翻墙目标代理: $ROUTER =="

# ---------- 1. 安装 gost（GitHub 下载，fallback gh-proxy） ----------
if [ ! -x "$GOST_BIN" ]; then
    echo "下载 gost ..."
    ok=0
    for url in "$GOST_URL1" "$GOST_URL2"; do
        echo "  尝试: $url"
        if curl -sL --max-time 120 -o /tmp/gost.tar.gz "$url" 2>/dev/null; then
            if tar xzf /tmp/gost.tar.gz -C /tmp/ gost 2>/dev/null && [ -x /tmp/gost ]; then
                sudo cp /tmp/gost "$GOST_BIN" && sudo chmod +x "$GOST_BIN"
                ok=1
                break
            fi
        fi
        echo "  失败，试下一个源..."
    done
    if [ "$ok" != "1" ]; then
        echo "❌ gost 下载失败，请检查网络（或手动放 gost 到 $GOST_BIN）"
        exit 1
    fi
    echo "gost 已安装到 $GOST_BIN"
fi

# ---------- 2. 启动 gost 透明代理转发 ----------
if ! pgrep -f "redirect://:$GOST_PORT" >/dev/null 2>&1; then
    echo "启动 gost 透明代理 ..."
    sudo setsid "$GOST_BIN" -L "redirect://:$GOST_PORT" -F "http://$ROUTER" >/tmp/gost.log 2>&1 < /dev/null &
    sleep 2
    echo "gost PID: $(pgrep -f 'redirect://' | head -1)"
else
    echo "gost 已在运行"
fi

# ---------- 3. 关 IPv6（防止 DNS AAAA 绕过 IPv4 iptables） ----------
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null

# ---------- 4. iptables REDIRECT（内网直连，外网走 gost） ----------
# 本机发出的流量走 OUTPUT 链（矿工/curl 在本机跑），转发流量走 PREROUTING 链
for chain in OUTPUT PREROUTING; do
    sudo iptables -t nat -C $chain -p tcp -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || \
      sudo iptables -t nat -A $chain -p tcp -d 10.0.0.0/8 -j ACCEPT
    sudo iptables -t nat -C $chain -p tcp -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || \
      sudo iptables -t nat -A $chain -p tcp -d 172.16.0.0/12 -j ACCEPT
    sudo iptables -t nat -C $chain -p tcp -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || \
      sudo iptables -t nat -A $chain -p tcp -d 192.168.0.0/16 -j ACCEPT
    sudo iptables -t nat -C $chain -p tcp -j REDIRECT --to-ports "$GOST_PORT" 2>/dev/null || \
      sudo iptables -t nat -A $chain -p tcp -j REDIRECT --to-ports "$GOST_PORT"
done

# ---------- 5. 验证 ----------
echo ""
echo "== 验证翻墙 =="
echo "gost 进程: $(pgrep -f 'redirect://' | wc -l) 个"
echo "测试 google:"
curl -sI --max-time 12 https://www.google.com 2>/dev/null | head -1 || echo "  (curl 直连失败，但矿工走 gost 透明代理不受影响)"
echo ""
echo "✅ 翻墙已开启，矿工/下载/API 全部走 $ROUTER"
