#!/bin/bash
# ============================================
# TSC 云GPU 8×5090 算力实时监控
# 用法: bash watch_hashrate.sh
# 每5秒刷新 GPU 利用率/显存/功耗/温度
# ============================================

# ---- 配置区（改这里）----
HOST="root@f17fc415bd9a450596601ba0468e7322.region2.waas.aigate.cc"
PORT="46860"
PASS="在这里填SSH密码"
# --------------------------

command -v sshpass >/dev/null 2>&1 || { echo "请先安装 sshpass: sudo apt install sshpass"; exit 1; }

echo "=== TSC 8×5090 算力监控（Ctrl+C 退出）==="
while true; do
  clear
  echo "=== TSC 8×5090 算力监控  $(date '+%H:%M:%S') ==="
  echo "GPU | 利用率 | 显存 | 功耗 | 温度"
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 "$HOST" -p "$PORT" \
    'nvidia-smi --query-gpu=index,utilization.gpu,memory.used,power.draw,temperature.gpu --format=csv,noheader 2>/dev/null | awk -F", " "{printf \"  %s  |  %s%%  |  %s  |  %s  |  %s°C\n\", \$1, \$2, \$3, \$4, \$5}"'
  echo ""
  echo "racer 状态:"
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 "$HOST" -p "$PORT" \
    'pgrep -f "racer -o" >/dev/null && echo "  ✅ racer 运行中" || echo "  ❌ racer 未运行"'
  sleep 5
done
