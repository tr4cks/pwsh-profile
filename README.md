# pwsh-profile

For the moment, this configuration is only available on macOS.

First, you need to install PowerShell (version 7.2 or later), Oh-My-Posh, and a Nerd Font.
You will then need to set this font in each terminal where you want to use this configuration.

And finally:

```powershell
Install-Module -Name PSReadLine -Scope CurrentUser
Install-Module -Name CompletionPredictor -Repository PSGallery -Scope CurrentUser
```

```powershell
try { `
  $ErrorActionPreference = 'Stop'; `
  $myProfile = './profile.ps1'; `
  $myPoshConfig = './macos.omp.yaml'; `
  if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force } `
  Get-Content -Path $myProfile | Set-Content -Path $PROFILE; `
  Copy-Item -Path $myPoshConfig -Destination (Split-Path -Path $PROFILE -Parent); `
  & $PROFILE `
} finally { $ErrorActionPreference = 'Continue' }
```

# Contributing

To format the code:

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Import-Module PSScriptAnalyzer

Invoke-Formatter -ScriptDefinition (Get-Content -Path './profile.ps1' -Raw) > ./profile.ps1
```
