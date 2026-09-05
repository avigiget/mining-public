# C:\Windows 空间排查
# 用法：下载后右键"使用 PowerShell 运行"（管理员权限能看到全部）
Write-Host "========== C:\Windows 空间排查 ==========" -ForegroundColor Green

Write-Host ""
Write-Host "===== 1. C:\Windows 顶层子文件夹（从大到小）=====" -ForegroundColor Cyan
Get-ChildItem C:\Windows -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Select-Object -First 20 | Format-Table -AutoSize

Write-Host "===== 2. 常见可清理项的具体大小 ===== 大小" -ForegroundColor Cyan
$cleanTargets = @(
  @{ Name="更新缓存(SoftwareDistribution\Download)"; Path="C:\Windows\SoftwareDistribution\Download" },
  @{ Name="临时文件(Temp)"; Path="C:\Windows\Temp" },
  @{ Name="安装包缓存(Installer)"; Path="C:\Windows\Installer" },
  @{ Name="日志(Logs)"; Path="C:\Windows\Logs" },
  @{ Name="预读(Prefetch)"; Path="C:\Windows\Prefetch" },
  @{ Name="组件存储(WinSxS)"; Path="C:\Windows\WinSxS" },
  @{ Name="错误转储(Minidump)"; Path="C:\Windows\Minidump" },
  @{ Name="内存转储(MEMORY.DMP)"; Path="C:\Windows\MEMORY.DMP" },
  @{ Name="系统日志(CBS)"; Path="C:\Windows\Logs\CBS" }
)
foreach ($c in $cleanTargets) {
  if (Test-Path $c.Path) {
    $s = (Get-ChildItem $c.Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    Write-Host ("{0,-40} {1,8:N2} GB" -f $c.Name, ($s/1GB))
  } else {
    Write-Host ("{0,-40} 不存在" -f $c.Name)
  }
}

Write-Host ""
Write-Host "===== 3. C:\Windows 下最大的 20 个文件 ===== 大小" -ForegroundColor Cyan
Get-ChildItem C:\Windows -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 @{N='GB';E={[math]::Round($_.Length/1GB,2)}}, Name | Format-Table -AutoSize

Write-Host ""
Write-Host "========== 排查完成 ==========" -ForegroundColor Green
Write-Host "提示：建议用管理员 PowerShell 运行，否则部分系统目录读不全" -ForegroundColor Yellow
Read-Host "按回车键退出"
