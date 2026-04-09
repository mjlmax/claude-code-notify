param(
    [switch]$Uninstall
)

$protocolKey = 'HKCU:\Software\Classes\claude-focus'
$vbsPath = Join-Path $PSScriptRoot 'focus-claude.vbs'

if ($Uninstall) {
    if (Test-Path $protocolKey) {
        Remove-Item -Path $protocolKey -Recurse -Force
        Write-Host "[OK] claude-focus:// protocol unregistered."
    } else {
        Write-Host "[SKIP] claude-focus:// protocol not found."
    }
    return
}

# Register claude-focus:// protocol handler
New-Item -Path $protocolKey -Force | Out-Null
Set-ItemProperty -Path $protocolKey -Name '(Default)' -Value 'URL:Claude Focus Protocol'
Set-ItemProperty -Path $protocolKey -Name 'URL Protocol' -Value ''
New-Item -Path "$protocolKey\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$protocolKey\shell\open\command" -Name '(Default)' -Value "wscript.exe `"$vbsPath`""

Write-Host "[OK] claude-focus:// protocol registered."
Write-Host "     Handler: wscript.exe `"$vbsPath`""
Write-Host ""
Write-Host "Test it:  Start-Process 'claude-focus://'"
