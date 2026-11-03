# Makes Claude Code's global memory use an existing AGENTS.md, matches link-claude-md.sh
#   No CLAUDE.md: creates one holding a single `@` import
#   Same content as AGENTS.md: backs it up and replaces it with the import
#   Different content: backs it up and adds the import at the top, keeping the rest
# Creates no symlinks, so Developer Mode is not needed; idempotent
# Usage: link-claude-md.ps1 [path to AGENTS.md], defaults to AGENTS.md in the Codex home
& {
  $ErrorActionPreference = 'Stop'

  function Get-RealPath($path) {
    $item = Get-Item -LiteralPath $path -Force
    $link = @($item.Target)[0]
    if ($link) { [IO.Path]::GetFullPath([IO.Path]::Combine($item.DirectoryName, $link)) } else { $item.FullName }
  }

  $codexDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $agents = if ($args[0]) { $args[0] } else { Join-Path $codexDir 'AGENTS.md' }
  $claudeMd = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
  $stamp = Get-Date -Format 'yyyyMMddHHmmss'

  if (-not (Test-Path -LiteralPath $agents -PathType Leaf)) { throw "not found: $agents" }
  $agents = (Resolve-Path -LiteralPath $agents).ProviderPath
  if (-not [IO.File]::ReadAllBytes($agents).Length) { throw "empty file: $agents" }

  # Paths under the home folder use ~, which also covers user names with spaces
  $prefix = $env:USERPROFILE.TrimEnd('\') + '\'
  if ($agents.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    $import = '@~/' + $agents.Substring($prefix.Length).Replace('\', '/')
  } else {
    $import = '@' + $agents.Replace('\', '/')
  }

  New-Item -ItemType Directory -Force -Path (Split-Path $claudeMd) | Out-Null

  $exists = Test-Path -LiteralPath $claudeMd
  if ($exists -and ((Get-RealPath $claudeMd) -eq (Get-RealPath $agents))) {
    Write-Host 'skip   already the same file'
    return
  }
  $same = $exists -and ((Get-FileHash -LiteralPath $claudeMd).Hash -eq (Get-FileHash -LiteralPath $agents).Hash)
  if ($exists -and -not $same -and [IO.File]::ReadAllText($claudeMd).Contains($import)) {
    Write-Host 'skip   import already present'
    return
  }
  if ($import -match '\s') { throw "path contains whitespace, cannot be imported: $agents" }

  $body = [Text.Encoding]::UTF8.GetBytes("$import`n")
  if ($exists -and -not $same) {
    $body = [byte[]]([Text.Encoding]::UTF8.GetBytes("$import`n`n") + [IO.File]::ReadAllBytes($claudeMd))
  }
  if ($exists) {
    Copy-Item -LiteralPath $claudeMd -Destination "$claudeMd.bak.$stamp"
    Write-Host "backup $claudeMd.bak.$stamp"
  }
  # Same content may mean a hard link, so drop this name first to keep AGENTS.md intact
  if ($same) { Remove-Item -LiteralPath $claudeMd }
  [IO.File]::WriteAllBytes($claudeMd, $body)
  Write-Host "import $claudeMd"
} @args
