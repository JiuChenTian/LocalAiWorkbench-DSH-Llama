param([string]$PackageRoot = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($PackageRoot).TrimEnd('\','/')
for ($ancestor = $root; $ancestor; $ancestor = [IO.Path]::GetDirectoryName($ancestor)) {
    if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Linked package path rejected: $ancestor"
    }
}
if (Test-Path -LiteralPath (Join-Path $root 'BUILD-INCOMPLETE.txt')) { throw 'Package build is incomplete.' }
$manifest = Get-Content -LiteralPath (Join-Path $root 'package-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.formatVersion -ne 1 -or -not $manifest.files -or $manifest.files -isnot [array]) { throw 'Unsupported or empty package manifest.' }
$expected = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $manifest.files) {
    $relative = $entry.path
    if ($relative -isnot [string] -or $relative -match '[\\:]' -or $relative.StartsWith('/') -or
        $relative -match '(^|/)(\.{1,2}|)(/|$)' -or $relative -match '[. ](/|$)' -or
        $relative -ieq 'package-manifest.json' -or $relative -ieq 'BUILD-INCOMPLETE.txt') {
        throw "Invalid manifest path: $relative"
    }
    if ($entry.sha256 -isnot [string] -or $entry.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        ($entry.size -isnot [long] -and $entry.size -isnot [int]) -or $entry.size -lt 0) {
        throw "Invalid manifest metadata: $relative"
    }
    if ($expected.ContainsKey($relative)) { throw "Duplicate manifest path: $relative" }
    $expected.Add($relative, $entry)
}
$pending = [Collections.Generic.Stack[string]]::new()
$pending.Push($root)
$count = 0
$bytes = 0L
while ($pending.Count -gt 0) {
    foreach ($file in Get-ChildItem -LiteralPath $pending.Pop() -Force) {
        if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked package entry rejected: $($file.FullName)" }
        if ($file.PSIsContainer) { $pending.Push($file.FullName); continue }
        $relative = $file.FullName.Substring($root.Length + 1).Replace('\','/')
        if ($relative -ieq 'package-manifest.json') { continue }
        if (-not $expected.ContainsKey($relative)) { throw "Unexpected package file: $relative" }
        $entry = $expected[$relative]
        if ($file.Length -ne $entry.size) { throw "Size mismatch: $relative" }
        if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ine $entry.sha256) { throw "SHA-256 mismatch: $relative" }
        $expected.Remove($relative) | Out-Null
        $count++
        $bytes += $file.Length
    }
}
if ($expected.Count -gt 0) { throw "Missing package files: $([string]::Join(', ', $expected.Keys))" }
Write-Host "Package integrity verified: $count files; $bytes bytes."
Write-Host 'Integrity only; this does not certify authenticity or offline release readiness.'
