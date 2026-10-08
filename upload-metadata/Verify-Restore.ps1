param([switch]$RestoreAttributes)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$rows = @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'files-sha256.csv') -Encoding UTF8)
$dirs = @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'directories.csv') -Encoding UTF8)
foreach ($row in $rows) {
    $target = Join-Path $root $row.Path
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Missing: $($row.Path)" }
    $item = Get-Item -LiteralPath $target -Force
    if ($item.Length -ne [long]$row.Bytes) { throw "Size mismatch (run git lfs pull): $($row.Path)" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $row.SHA256) { throw "SHA256 mismatch: $($row.Path)" }
}
if ($RestoreAttributes) {
    foreach ($row in $dirs) { $target=Join-Path $root $row.Path; if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null } }
    foreach ($row in $rows) { $target=Join-Path $root $row.Path; [IO.File]::SetLastWriteTimeUtc($target,[datetime]::Parse($row.LastWriteTimeUtc).ToUniversalTime()); [IO.File]::SetAttributes($target,[IO.FileAttributes][int]$row.Attributes) }
    foreach ($row in $dirs | Sort-Object { $_.Path.Length } -Descending) { $target=Join-Path $root $row.Path; [IO.Directory]::SetLastWriteTimeUtc($target,[datetime]::Parse($row.LastWriteTimeUtc).ToUniversalTime()); [IO.File]::SetAttributes($target,[IO.FileAttributes][int]$row.Attributes) }
}
Write-Output "Verified $($rows.Count) original files: all SHA256 hashes match."