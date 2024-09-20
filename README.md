# pwsh-profile

This PowerShell profile has been specifically designed to adapt syntax highlighting for both dark and light modes, ensuring optimal readability in either theme. It leverages ANSI 256 colors, providing a wide range of vibrant and subtle tones. As a result, the profile integrates seamlessly with macOS Terminal, taking full advantage of its color capabilities. For now, I encourage you to explore the profile to see the available commands and options tailored to enhance your terminal experience.

> For the moment, this configuration is only available on macOS.

First, you need to install [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4) (version 7.2 or later), [Oh-My-Posh](https://ohmyposh.dev/), and a [Nerd Font](https://www.nerdfonts.com/).
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
