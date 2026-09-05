# 查大头文件夹内部（WPS/腾讯/剪映/Chrome 具体是什么占空间）
# 用法：下载后右键"使用 PowerShell 运行"
Write-Host "========== 大头文件夹内部排查 ==========" -ForegroundColor Green

$targets = @(
  @{ Name="WPS-Local(kingsoft)"; Path="C:\Users\$env:USERNAME\AppData\Local\kingsoft" },
  @{ Name="WPS-Roaming(Kingsoft)"; Path="C:\Users\$env:USERNAME\AppData\Roaming\Kingsoft" },
  @{ Name="腾讯Tencent(Local)"; Path="C:\Users\$env:USERNAME\AppData\Local\Tencent" },
  @{ Name="剪映JianyingPro"; Path="C:\Users\$env:USERNAME\AppData\Roaming\JianyingPro" },
  @{ Name="Chrome(Google)"; Path="C:\Users\$env:USERNAME\AppData\Roaming\Google" },
  @{ Name="Microsoft(Roaming)"; Path="C:\Users\$env:USERNAME\AppData\Roaming\Microsoft" }
)

foreach ($t in $targets) {
  Write-Host ""
  Write-Host ("===== " + $t.Name + " =====") -ForegroundColor Cyan
  if (Test-Path $t.Path) {
    Get-ChildItem $t.Path -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
      $s = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
      [PSCustomObject]@{Name=$_.Name; GB=[math]::Round($s/1GB,2)}
    } | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize
  } else {
    Write-Host "路径不存在: $($t.Path)"
  }
}

Write-Host ""
Write-Host "========== 排查完成 ==========" -ForegroundColor Green
Read-Host "按回车键退出"
