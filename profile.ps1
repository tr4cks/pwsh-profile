# Minimum PowerShell version: 7.2
# -------------------------------

using namespace System.Management.Automation.Language

# ==============================================================================
#  Load Modules
# ------------------------------------------------------------------------------

function Load-ModuleSafely {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [string]$AdditionalText = $null
    )

    try {
        Import-Module $ModuleName -ErrorAction Stop
    }
    catch {
        $errorMessage = "Module '$ModuleName' not available or error loading it."
        if ($AdditionalText -ne $null) {
            $errorMessage += "`n$AdditionalText"
        }
        throw $errorMessage
    }
}

try {
    Load-ModuleSafely -ModuleName PSReadLine -AdditionalText "$> Install-Module -Name PSReadLine -Scope CurrentUser"
    Load-ModuleSafely -ModuleName CompletionPredictor -AdditionalText "$> Install-Module -Name CompletionPredictor -Repository PSGallery -Scope CurrentUser"
}
catch {
    Write-Error $_
    exit 1
}
finally {
    Remove-Item -Path Function:\Load-ModuleSafely
}


# ==============================================================================
#  Set Aliases
# ------------------------------------------------------------------------------

Set-Alias ll Get-ChildItem
Set-Alias title Set-TerminalTitle
Set-Alias rtitle Reset-TerminalTitle
Set-Alias ups Update-PSStyle


# ==============================================================================
#  General Settings
# ------------------------------------------------------------------------------

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward


# ==============================================================================
#  Theme Settings
# ------------------------------------------------------------------------------

enum ColorLayer {
    Background = 48
    Foreground = 38
}

function Get-Ansi256Color {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Color,
        [ColorLayer]$Layer = [ColorLayer]::Foreground
    )

    return "$([char]0x1B)[$([int]$Layer);5;${Color}m"
}

switch ($true) {
    { $IsWindows } {
        throw [System.NotImplementedException] "This feature is not implemented for Windows."
        break
    }

    { $IsLinux } {
        throw [System.NotImplementedException] "This feature is not implemented for Linux."
        break
    }

    { $IsMacOS } {
        $env:PATH += ":/opt/homebrew/bin:/opt/homebrew/sbin"

        function Load-PSStyleForMacOS {
            param (
                [Parameter(Mandatory = $true)]
                [bool]$DarkMode
            )
        
            $continuationPromptGlyph = "$([char]0x2570)$([char]0x2500)["
            Set-PSReadLineOption -ContinuationPrompt $continuationPromptGlyph
        
            if ($DarkMode) {
                $promptGlyph = [char]0xe285
                Set-PSReadLineOption -PromptText "$(Get-Ansi256Color -Color 222)$promptGlyph$($PSStyle.Reset) ", "$promptGlyph "
        
                Set-PSReadLineOption -Colors @{
                    ContinuationPrompt     = Get-Ansi256Color -Color 222
                    Emphasis               = Get-Ansi256Color -Color 222
                    Error                  = Get-Ansi256Color -Color 197
                    # Selection
                    Default                = Get-Ansi256Color -Color 188
                    Comment                = (Get-Ansi256Color -Color 102) + $PSStyle.Italic
                    Keyword                = Get-Ansi256Color -Color 116
                    String                 = Get-Ansi256Color -Color 219
                    Operator               = Get-Ansi256Color -Color 188
                    Variable               = Get-Ansi256Color -Color 188
                    Command                = Get-Ansi256Color -Color 222
                    Parameter              = Get-Ansi256Color -Color 188
                    Type                   = (Get-Ansi256Color -Color 117) + $PSStyle.Italic
                    Number                 = Get-Ansi256Color -Color 141
                    Member                 = Get-Ansi256Color -Color 188
                    InlinePrediction       = (Get-Ansi256Color -Color 102)
                    ListPrediction         = Get-Ansi256Color -Color 222
                    ListPredictionSelected = Get-Ansi256Color -Color 237 -Layer Background
                }
            }
            else {
                $promptGlyph = [char]0xe285
                Set-PSReadLineOption -PromptText "$(Get-Ansi256Color -Color 236)$promptGlyph$($PSStyle.Reset) ", "$promptGlyph "
        
                Set-PSReadLineOption -Colors @{
                    ContinuationPrompt     = Get-Ansi256Color -Color 236
                    Emphasis               = Get-Ansi256Color -Color 55
                    Error                  = Get-Ansi256Color -Color 197
                    # Selection
                    Default                = Get-Ansi256Color -Color 236
                    Comment                = (Get-Ansi256Color -Color 243) + $PSStyle.Italic
                    Keyword                = Get-Ansi256Color -Color 19
                    String                 = Get-Ansi256Color -Color 22
                    Operator               = Get-Ansi256Color -Color 236
                    Variable               = Get-Ansi256Color -Color 236
                    Command                = Get-Ansi256Color -Color 55
                    Parameter              = Get-Ansi256Color -Color 236
                    Type                   = (Get-Ansi256Color -Color 19) + $PSStyle.Italic
                    Number                 = Get-Ansi256Color -Color 90
                    Member                 = Get-Ansi256Color -Color 236
                    InlinePrediction       = (Get-Ansi256Color -Color 243)
                    ListPrediction         = Get-Ansi256Color -Color 55
                    ListPredictionSelected = Get-Ansi256Color -Color 254 -Layer Background
                }
            }
        }

        enum ThemeMode {
            Default
            Dark
            Light
        }

        function Load-PSStyle {
            param (
                [switch]$ForceDefault,
                [ThemeMode]$Theme = [ThemeMode]::Default
            )

            $env:VIRTUAL_ENV_DISABLE_PROMPT = 1

            if ($Theme -ne [ThemeMode]::Default) {
                $env:TERM_DARK_MODE = if ($Theme -eq [ThemeMode]::Dark) { "true" } else { "false" }
            }

            switch ($true) {
                { $env:TERM_PROGRAM -eq "Apple_Terminal" } {
                    if (-not $env:TERM_DARK_MODE -or $ForceDefault) {
                        $env:TERM_DARK_MODE = (& osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode').ToLower()
                    }

                    # The order in which the next 2 lines are defined is important.
                    oh-my-posh init pwsh --config "$(Split-Path -Path $PROFILE -Parent)/macos.omp.yaml" | Invoke-Expression
                    Load-PSStyleForMacOS -DarkMode ($env:TERM_DARK_MODE -eq "true")
                    break
                }

                { $env:TERM_PROGRAM -eq "iTerm.app" } {
                    if (-not $env:TERM_DARK_MODE -or $Force) {
                        $env:TERM_DARK_MODE = "true"
                    }

                    # The order in which the next 2 lines are defined is important.
                    oh-my-posh init pwsh --config "$(Split-Path -Path $PROFILE -Parent)/macos.omp.yaml" | Invoke-Expression
                    Load-PSStyleForMacOS -DarkMode ($env:TERM_DARK_MODE -eq "true")                    
                    break
                }

                default {
                    if (-not $env:TERM_DARK_MODE -or $Force) {
                        $env:TERM_DARK_MODE = "true"
                    }

                    # The order in which the next 2 lines are defined is important.
                    oh-my-posh init pwsh --config "$(Split-Path -Path $PROFILE -Parent)/macos.omp.yaml" | Invoke-Expression
                    Load-PSStyleForMacOS -DarkMode ($env:TERM_DARK_MODE -eq "true")                    
                }
            }
        }
        break
    }

    default {
        throw [System.NotImplementedException] "The operating system or feature is not implemented for this platform."
    }
}

Load-PSStyle


# ==============================================================================
#  Public Functions
# ------------------------------------------------------------------------------

function Update-PSStyle {
    Load-PSStyle -ForceDefault
}

enum TerminalTitleType {
    System
    Posh
}

function Set-TerminalTitle {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [TerminalTitleType]$Type = [TerminalTitleType]::Posh
    )

    switch ($Type) {
        ([TerminalTitleType]::System) {
            if ($Host.UI.RawUI -ne $null) {
                $Host.UI.RawUI.WindowTitle = $Title
            }
            else {
                Write-Error "The current host does not support changing the terminal title."
            }
        }
        ([TerminalTitleType]::Posh) {
            $env:POSH_TERM_TITLE = $Title
        }
    }
}

function Reset-TerminalTitle {
    param (
        [TerminalTitleType]$Type = [TerminalTitleType]::Posh
    )

    switch ($Type) {
        ([TerminalTitleType]::System) {
            if ($Host.UI.RawUI -ne $null) {
                $Host.UI.RawUI.WindowTitle = [string]::Empty
            }
            else {
                Write-Error "The current host does not support changing the terminal title."
            }
        }
        ([TerminalTitleType]::Posh) {
            if ($env:POSH_TERM_TITLE) {
                Remove-Item -Path "Env:POSH_TERM_TITLE"
            }
        }
    }
}


# ==============================================================================
#  Shortcuts
# ------------------------------------------------------------------------------

# Shortcut to delete one command from the history
Set-PSReadLineKeyHandler -Key Ctrl+Subtract -ScriptBlock {
    $in = [string]::Empty
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$in, [ref]$null)

    if ([string]::IsNullOrWhiteSpace($in) -or
        -not ([Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems() | ? { $_.CommandLine -ceq $in })) {
        return
    }

    $historyPath = (Get-PSReadLineOption).HistorySavePath

    # Only way to "refresh" the history in the current session is to clear it
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    $content = [System.IO.File]::ReadAllLines($historyPath)
    Clear-Content $historyPath

    $content | % {
        if ($_ -cne $in) {            
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($_)
        }
    }
}


# ==============================================================================
#  Import Scripts from:
#  https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
# ------------------------------------------------------------------------------

#region Smart Insert/Delete

# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.

Set-PSReadLineKeyHandler -Key '"', "'" `
    -BriefDescription SmartInsertQuote `
    -LongDescription "Insert paired quotes if not already on a quote" `
    -ScriptBlock {
    param($key, $arg)

    $quote = $key.KeyChar

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If text is selected, just quote it without any smarts
    if ($selectionStart -ne -1) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        return
    }

    $ast = $null
    $tokens = $null
    $parseErrors = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

    function FindToken {
        param($tokens, $cursor)

        foreach ($token in $tokens) {
            if ($cursor -lt $token.Extent.StartOffset) { continue }
            if ($cursor -lt $token.Extent.EndOffset) {
                $result = $token
                $token = $token -as [StringExpandableToken]
                if ($token) {
                    $nested = FindToken $token.NestedTokens $cursor
                    if ($nested) { $result = $nested }
                }

                return $result
            }
        }
        return $null
    }

    $token = FindToken $tokens $cursor

    # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
    if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
        # If we're at the start of the string, assume we're inserting a new string
        if ($token.Extent.StartOffset -eq $cursor) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }

        # If we're at the end of the string, move over the closing quote if present.
        if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }
    }

    if ($null -eq $token -or
        $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
        if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
            # Odd number of quotes before the cursor, insert a single quote
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
        }
        else {
            # Insert matching quotes, move cursor to be in between the quotes
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
        return
    }

    # If cursor is at the start of a token, enclose it in quotes.
    if ($token.Extent.StartOffset -eq $cursor) {
        if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
            $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
            $end = $token.Extent.EndOffset
            $len = $end - $cursor
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
            return
        }
    }

    # We failed to be smart, so just insert a single quote
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(', '{', '[' `
    -BriefDescription InsertPairedBraces `
    -LongDescription "Insert matching braces" `
    -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        <#case#> '(' { [char]')'; break }
        <#case#> '{' { [char]'}'; break }
        <#case#> '[' { [char]']'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
    if ($selectionStart -ne -1) {
        # Text is selected, wrap it in brackets
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else {
        # No text is selected, insert a pair
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
    -BriefDescription SmartCloseBraces `
    -LongDescription "Insert closing brace or skip" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar) {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    }
}

Set-PSReadLineKeyHandler -Key Backspace `
    -BriefDescription SmartBackspace `
    -LongDescription "Delete previous character or matching quotes/parens/braces" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0) {
        $toMatch = $null
        if ($cursor -lt $line.Length) {
            switch ($line[$cursor]) {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

#endregion Smart Insert/Delete
