# tier-probe.ps1 -- read ONE engine log and print the tier's actual footprint.
# (Chinese display name kept OUT of the file on purpose: this file must be ASCII-only, see below.)
#
# WHY: R6 of the release checklist says a startup log must state the tier actually in use and its
# footprint. This probe is the consumer of that requirement: it normalizes what the engine logged
# into PROBE_* lines, and -- just as important -- prints UNKNOWN for anything the engine does NOT
# log, so a missing field shows up as evidence instead of being silently absent.
#
# ASCII-only on purpose (run by powershell.exe 5.1): this file's Chinese display name is
# spelled out in README.md, because a non-ASCII byte here would be read as ANSI and break parsing.
# Usage:  powershell -File <this file> -Log <engine stderr log> [-Required 'device,capacity,listening']
# Verdicts: PROBE_* lines + PROBE_VERDICT=PASS|FAIL ; exit 0/1 (FAIL when a REQUIRED field is missing).
param(
  [Parameter(Mandatory = $true)][string]$Log,
  [string]$Required = 'device,kv_tokens,listening',
  [int]$Port = 8090
)
$ErrorActionPreference = 'Continue'
if (-not (Test-Path -LiteralPath $Log)) { Write-Host ('PROBE_LOG=MISSING ' + $Log); Write-Host 'PROBE_VERDICT=FAIL'; exit 2 }
$text = [IO.File]::ReadAllText($Log)
$fields = @{}

# device profile (hardware class + routed keys + origin)
$m = [regex]::Match($text, 'device profile ([^\s:]+): (\d+) routed keys(?:\s*\(([^)]*)\))?')
if ($m.Success) {
  $fields['device']       = $m.Groups[1].Value
  $fields['routed_keys']  = $m.Groups[2].Value
  $fields['profile_origin'] = if ($m.Groups[3].Success) { $m.Groups[3].Value } else { 'UNKNOWN' }
} else { $fields['device'] = 'UNKNOWN' }

# capacity | KV N tokens, dtype, mode | pages X/Y | runtime R | free F
$m = [regex]::Match($text, 'capacity \| KV ([\d,]+) tokens, ([a-z0-9]+), ([a-z]+) \| pages ([\d,]+)/([\d,]+) \| runtime ([^|]+) \| free ([^\r\n]+)')
if ($m.Success) {
  $fields['kv_tokens']   = $m.Groups[1].Value
  $fields['kv_dtype']    = $m.Groups[2].Value
  $fields['capacity_mode'] = $m.Groups[3].Value
  $fields['pool_pages']  = $m.Groups[4].Value
  $fields['logical_pages'] = $m.Groups[5].Value
  $fields['runtime']     = $m.Groups[6].Value.Trim()
  $fields['free_vram']   = $m.Groups[7].Value.Trim()
} else { $fields['kv_tokens'] = 'UNKNOWN' }

# context cache | ... host H states, K KV ...
$m = [regex]::Match($text, 'context cache \| (\d+) active \+ (\d+) cached device states \| host ([\d,]+) states, ([^|]+) KV')
if ($m.Success) {
  $fields['lanes']        = $m.Groups[1].Value
  $fields['cached_states'] = $m.Groups[2].Value
  $fields['host_states']  = $m.Groups[3].Value
  $fields['host_kv']      = $m.Groups[4].Value.Trim()
} else { $fields['host_kv'] = 'UNKNOWN' }

# reuse gate + listening
$m = [regex]::Match($text, '\[ninfer\] reuse host-backed: (on|off)')
$fields['reuse_gate'] = if ($m.Success) { $m.Groups[1].Value.ToUpperInvariant() } else { 'UNKNOWN' }
$m = [regex]::Match($text, 'listening on http://[^:]+:(\d+)')
$fields['listening'] = if ($m.Success) { $m.Groups[1].Value } else { 'UNKNOWN' }

# weight load (context for the VRAM sum)
$m = [regex]::Match($text, 'loading weights \| ([^\r\n]+)')
$fields['weights'] = if ($m.Success) { $m.Groups[1].Value.Trim() } else { 'UNKNOWN' }

# ---- footprint the engine does NOT log today (R6 gap, reported as such) ----
# The host page stride IS known to the engine (it is used to size the host tier) and the guard line
# prints host_pages for a given --host-kv-mib; but no startup line states bytes/token yet.
$bytesPerToken = 'UNKNOWN'
$m = [regex]::Match($text, 'host_pages=(\d+)')
if ($m.Success) { $fields['guard_host_pages'] = $m.Groups[1].Value }

foreach ($k in ($fields.Keys | Sort-Object)) { Write-Host ('PROBE_' + $k.ToUpperInvariant() + '=' + $fields[$k]) }
Write-Host ('PROBE_KV_BYTES_PER_TOKEN=' + $bytesPerToken + '  # R6 GAP: no startup line states bytes/token yet')

# ---- required-field gate -------------------------------------------------
# NOTE: the required names are FIELD KEYS, not free text. 'capacity' is accepted as an alias for
# 'kv_tokens' because that is what the engine log line is called; a mismatch here shows up as a
# bogus PROBE_MISSING (measured: first run reported "missing=capacity" while kv_tokens was parsed).
$alias = @{ 'capacity' = 'kv_tokens'; 'profile' = 'device'; 'gate' = 'reuse_gate' }
$missing = @()
foreach ($r in ($Required -split ',')) {
  $r = $r.Trim()
  if ($r -eq '') { continue }
  if ($alias.ContainsKey($r)) { $r = $alias[$r] }
  $v = if ($fields.ContainsKey($r)) { $fields[$r] } else { 'UNKNOWN' }
  if ($v -eq 'UNKNOWN') { $missing += $r }
}
Write-Host ('PROBE_MISSING=' + $missing.Count + $(if ($missing.Count) { '  :: ' + ($missing -join ',') } else { '' }))
Write-Host ('PROBE_VERDICT=' + $(if ($missing.Count -eq 0) { 'PASS' } else { 'FAIL' }))
if ($missing.Count -eq 0) { exit 0 } else { exit 1 }
