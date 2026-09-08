# 矿机翻墙手册（fanqiang.sh）

透明代理翻墙：整机出站 TCP 流量走软路由 HTTP 代理，矿工/下载/API 无感知。

## 1. 下载脚本

```bash
curl -sL -o fanqiang.sh https://gh-proxy.com/https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang.sh
```

> GitHub 直连可用时用 raw 直连：
> `curl -sL -o fanqiang.sh https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang.sh`

## 2. 运行翻墙（root 下执行）

```bash
# 潘山
sh fanqiang.sh 192.168.7.2:26779

# 金山
sh fanqiang.sh 192.168.9.1:26779

# 丰州
sh fanqiang.sh 192.168.9.1:26779
```

## 3. 验证翻墙结果

```bash
echo "== gost进程 =="; pgrep -af 'redirect://' || echo "❌ gost没跑"; echo "== iptables规则 =="; iptables -t nat -L OUTPUT -n | grep -E 'REDIRECT|192.168.0.0/16|172.16|10.0.0'; echo "== IPv6(应为1=已关) =="; cat /proc/sys/net/ipv6/conf/all/disable_ipv6; echo "== 翻墙测试 =="; curl -sI --max-time 12 https://www.google.com | head -1 || echo "❌ 翻墙失败"
```

### 结果对照

| 检查项 | 正常的样子 |
|---|---|
| gost 进程 | 有 `gost ... -L redirect://:12345` 一行 |
| iptables | `REDIRECT ... redir ports 12345` + 三条内网 ACCEPT（10.0.0/172.16/192.168） |
| IPv6 | 输出 `1`（= 已关闭） |
| 翻墙测试 | `HTTP/2 200`（google 通 = 透明代理生效） |

## 注意事项

- **需 root 或 sudo**（脚本含 iptables / sysctl 特权操作）
- **重启后失效**，需重新运行一次（gost 不重复下载，几秒完成）
- gost 本体存 `/usr/local/bin/gost`，重启不删，只有首次运行才下载
- 取消翻墙：`sh fanqiang.sh off`
