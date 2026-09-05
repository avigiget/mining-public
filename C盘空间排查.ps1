# C盘空间排查脚本
# 用法：下载后右键此文件 -> "使用 PowerShell 运行"（或 PowerShell 里执行 .\C盘空间排查.ps1）
Write-Host "========== C盘空间排查 ==========" -ForegroundColor Green

Write-Host ""
Write-Host "===== 1. C盘顶层文件夹（从大到小）=====" -ForegroundColor Cyan
Get-ChildItem C:\ -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "===== 2. C盘根目录大文件（休眠/页面文件）=====" -ForegroundColor Cyan
Get-ChildItem C:\ -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 10 @{N='GB';E={[math]::Round($_.Length/1GB,2)}}, Name | Format-Table -AutoSize

Write-Host "===== 3. Users 各账号 ===== 大小" -ForegroundColor Cyan
Get-ChildItem C:\Users -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "===== 4. 用户目录 C:\Users\$env:USERNAME 下各文件夹 ===== 大小" -ForegroundColor Cyan
Get-ChildItem C:\Users\$env:USERNAME -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "===== 5. AppData\Local（软件缓存）=====" -ForegroundColor Cyan
Get-ChildItem C:\Users\$env:USERNAME\AppData\Local -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "===== 6. AppData\Roaming（软件配置缓存）=====" -ForegroundColor Cyan
Get-ChildItem C:\Users\$env:USERNAME\AppData\Roaming -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "===== 7. 最大的 30 个文件 ===== 大小" -ForegroundColor Cyan
Get-ChildItem C:\Users\$env:USERNAME -Recurse -File -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 30 @{N='GB';E={[math]::Round($_.Length/1GB,2)}}, FullName | Format-Table -AutoSize

Write-Host ""
Write-Host "========== 排查完成 ==========" -ForegroundColor Green
Write-Host "提示：别删含 wallet/key/keystore 的文件夹（挖矿钱包）" -ForegroundColor Yellow
Write-Host ""
Read-Host "按回车键退出"
