param(
  [Parameter(Mandatory=$true)]
  [string]$FolderPath,

  [switch]$Recurse,

  # 输出路径（默认当前目录）
  [string]$OutCsv = "c:\temp\logs-86\filtered_results.csv",
  [string]$OutTxt = "c:\temp\logs-86\filtered_hits.txt"
)

$senderTarget  = "HZJ@MAIL.CHIMEI.COM.CN"
$subjectTarget = "省厅'四不两直'执法检查迎检沟通协调会"

# 兼容 "Sender:" / "Sender=" 以及可能的空格
$senderRegex  = "(?im)^\s*Sender\s*[:=]\s*$([regex]::Escape($senderTarget))\s*$"
$subjectRegex = "(?im)^\s*MessageSubject\s*[:=]\s*$([regex]::Escape($subjectTarget))\s*$"

$files = Get-ChildItem -Path $FolderPath -Filter *.log -File -ErrorAction Stop -Recurse:$Recurse

$results = New-Object System.Collections.Generic.List[object]

foreach ($f in $files) {
  try {
    # -Raw：一次性读入整文件，适合做跨行匹配；大文件也能用，但会占内存（见下方“B.大文件流式”）
    $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop

    # 同一个文件中同时命中 sender+subject
    if ($content -match $senderRegex -and $content -match $subjectRegex) {

      # 进一步：把命中所在的“行”提取出来，便于人工核对
      $lines = Get-Content -LiteralPath $f.FullName -ErrorAction Stop
      $hitLines = @()

      for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "(?i)\bSender\s*[:=]\s*$([regex]::Escape($senderTarget))\b" -or
            $lines[$i] -match "(?i)\bMessageSubject\s*[:=]\s*$([regex]::Escape($subjectTarget))\b") {

          # 记录上下文：上一行/当前行/下一行
          $start = [Math]::Max(0, $i-1)
          $end   = [Math]::Min($lines.Count-1, $i+1)
          $ctx = ($lines[$start..$end] -join "`n")
          $hitLines += "---- $($f.FullName) @ line $($i+1) ----`n$ctx`n"
        }
      }

      $results.Add([pscustomobject]@{
        FileName   = $f.Name
        FullPath   = $f.FullName
        SizeKB     = [Math]::Round($f.Length / 1KB, 2)
        MatchSender  = $true
        MatchSubject = $true
      })

      # 把命中上下文写到 txt（追加）
      $hitLines | Out-File -FilePath $OutTxt -Encoding UTF8 -Append
    }
  }
  catch {
    Write-Warning "Failed to read file: $($f.FullName). Error: $($_.Exception.Message)"
  }
}

# 输出汇总 CSV
$results | Sort-Object FullPath | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

Write-Host "Done. Matched files: $($results.Count)"
Write-Host "CSV: $OutCsv"
Write-Host "TXT: $OutTxt"
