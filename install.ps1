# Windows installer, matches install.sh
# Claude Code and Gemini CLI use their own plugin / extension mechanism, see README
#   Run inside the repo: installs in place
#   Run through irm: clones or pulls first
# Links skills into each detected harness with junctions, no admin rights or Developer Mode needed
# Adds the hooks folder to the user PATH for the check-punct command
# Idempotent; never touches harness config files
& {
  $ErrorActionPreference = 'Stop'

  $repoUrl = if ($env:SKILLS_REPO) { $env:SKILLS_REPO } else { 'https://github.com/liasica/skills.git' }
  $repoDir = if ($env:SKILLS_DIR) { $env:SKILLS_DIR } else { Join-Path $env:LOCALAPPDATA 'liasica-skills' }

  # Use the repo around this script, otherwise clone or pull
  if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'skills'))) {
    $repo = $PSScriptRoot
  } elseif (Test-Path (Join-Path $repoDir '.git')) {
    git -C $repoDir pull --ff-only -q
    if ($LASTEXITCODE) { throw "git pull failed: $repoDir" }
    $repo = $repoDir
    Write-Host "pull  $repoDir"
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path $repoDir) | Out-Null
    git clone -q $repoUrl $repoDir
    if ($LASTEXITCODE) { throw "git clone failed: $repoUrl" }
    $repo = $repoDir
    Write-Host "clone $repoDir"
  }

  # Codex reads ~\.agents\skills; SKILL_TARGETS adds more folders, separated by semicolons
  $codexDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $targets = @()
  if (Test-Path $codexDir) { $targets += Join-Path $env:USERPROFILE '.agents\skills' }
  if ($env:SKILL_TARGETS) { $targets += @($env:SKILL_TARGETS -split ';' | Where-Object { $_ }) }

  foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    foreach ($dir in Get-ChildItem (Join-Path $repo 'skills') -Directory) {
      $link = Join-Path $target $dir.Name
      $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
      if ($item) {
        if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
          Write-Host "skip  $link (real directory with the same name, left as is)"
          continue
        }
        # Removes the junction only, the target stays
        $item.Delete()
      }
      New-Item -ItemType Junction -Path $link -Target $dir.FullName | Out-Null
    }
    Write-Host "link  $target"
  }
  if (-not $targets) { Write-Host 'warn  no harness detected, set SKILL_TARGETS to its skills folder' }

  $hooks = Join-Path $repo 'hooks'
  $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
  if ($entries -notcontains $hooks) {
    [Environment]::SetEnvironmentVariable('Path', (($entries + $hooks) -join ';'), 'User')
    $env:Path = "$env:Path;$hooks"
    Write-Host "path  added to user PATH: $hooks, open a new terminal to use it"
  }

  Write-Host ''
  Write-Host 'done'
}
