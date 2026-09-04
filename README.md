# 矿机翻墙脚本（公开分发）

矿机整机翻墙，复制下面对应场地的**整行命令**，粘贴到矿机 SSH 里执行即可。

## 一键翻墙命令（4 个场地，直接复制整行）

**丰州：**
```bash
curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s 192.168.9.1:26779
```

**金山：**
```bash
curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s 192.168.9.1:26779
```

**潘山：**
```bash
curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s 192.168.7.2:26779
```

**郑国权（4070s-cc）：**
```bash
curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s 192.168.0.34:26779
```

## 验证翻墙成功

跑完后在矿机上执行：

```bash
curl -sI https://www.google.com
```

返回 `HTTP/2 200` 就是翻墙成功了。

## 取消翻墙

```bash
curl -sL https://raw.githubusercontent.com/avigiget/mining-public/main/fanqiang-client.sh | sudo bash -s off
```

## 说明

- 矿工/下载/API 全部走代理，外网 TCP 走代理、内网直连（不影响本场内网矿池代理）
- gost 二进制脚本内自动下载（gh-proxy 优先，约 25 秒一次性下载）
- 重启矿机后翻墙失效，需重跑（要永久生效需加开机自启）

## 脚本文件

- `fanqiang-client.sh` — 矿机整机翻墙客户端
- `fanqiang-server.sh` — 服务器端（裸服务器开 26779+1081 代理，备用，PassWall 已配好的软路由不用）
