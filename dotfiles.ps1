
function Confirm($title, $question) {
  $choices = "&Yes", "&No"
  $choice = $Host.UI.PromptForChoice($title, $question, $choices, 1)

  return $choice -eq 0
}

function Ensure-Directory($path) {
  if (Test-Path $path -PathType Container) {
    return
  }

  try {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  } catch {
    throw "Unable to create directory '$path': $($_.Exception.Message)"
  }
}

function Make-Symlink($target, $link) {
  if (-not (Test-Path $link -PathType Leaf)) {
    Write-Warning "Source file not found at: $link. Skipping."
    return
  }

  $targetDirectory = Split-Path -Parent $target

  try {
    Ensure-Directory $targetDirectory
  } catch {
    Write-Error $_
    return
  }

  if (-not (Test-Path $target)) {
    try {
      New-Item $target -ItemType SymbolicLink -Value $link | Out-Null
      Write-Host "Created symlink at: $target."
    } catch {
      Write-Error "Failed to create symlink at '$target': $($_.Exception.Message)"
    }
    return
  }

  try {
    $targetHash = (Get-FileHash $target -ErrorAction Stop).Hash
    $linkHash = (Get-FileHash $link -ErrorAction Stop).Hash
  } catch {
    Write-Warning "Unable to compare '$target' with '$link': $($_.Exception.Message)"
    $targetHash = $null
    $linkHash = $null
  }

  if ($null -ne $targetHash -and $targetHash -eq $linkHash) {
    Write-Host "Symlink exists at: $target. Skipping."
    return
  }

  $question = "Do you want to create a symlink at: $target? THIS WILL OVERWRITE THE EXISTING FILE!"

  if (-not (Confirm "[Symlink] -" $question)) {
    Write-Host "Skipping."
    return
  }

  try {
    New-Item $target -ItemType SymbolicLink -Value $link -Force | Out-Null
    Write-Host "Created symlink at: $target."
  } catch {
    Write-Error "Failed to create symlink at '$target': $($_.Exception.Message)"
  }
}

function Resolve-WindowsTerminalSettingsPath {
  $candidates = @(
    @{ Path = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"; RequiredParent = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe" },
    @{ Path = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"; RequiredParent = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe" },
    @{ Path = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json"; RequiredParent = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal" }
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate.Path -PathType Leaf) {
      return $candidate.Path
    }
  }

  foreach ($candidate in $candidates) {
    $parent = Split-Path -Parent $candidate.Path
    if ((Test-Path $candidate.RequiredParent -PathType Container) -or ($null -ne $parent -and (Test-Path $parent -PathType Container))) {
      return $candidate.Path
    }
  }

  return $null
}

$settingsTarget = Resolve-WindowsTerminalSettingsPath

if (-not $settingsTarget) {
  Write-Error "Unable to locate the Windows Terminal settings directory. Launch Windows Terminal once so it can create its configuration files, then re-run this script."
  exit 1
}

$settingsSource = Join-Path $PSScriptRoot "windows\terminal\settings.json"

Write-Host "Linking Windows Terminal settings to: $settingsTarget"
Make-Symlink $settingsTarget $settingsSource
