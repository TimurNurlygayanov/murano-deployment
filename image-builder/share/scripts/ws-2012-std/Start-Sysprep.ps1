param (
    [Switch] $BatchExecution
)

if (-not $BatchExecution) {
    $ConfirmationString = 'start sysprep'
    $UserResponse = Read-Host -Prompt @"

==========================================================
Please confirm that you want run sysprep on this computer.

Type '$ConfirmationString' to continue.
==========================================================

"@

    if ($UserResponse -ne $ConfirmationString) {
        Write-Host "Sorry, wrong confirmation string ($UserResponse)"
        return
    }
}

Write-Host "Enabling firewall profiles ..."
netsh advfirewall set allprofiles state on


Write-Host "Enabling RDP access ..."
& reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /f /v "fDenyTSConnections" /t REG_DWORD /d 0
& reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /f /v "UserAuthentication" /t REG_DWORD /d 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"


Write-Host "Stopping and cleaning after Murano Agent ..."
Stop-Service "Murano Agent" -Force
Remove-Item C:\Murano\Agent\log.txt -Force


Write-Host "Stopping and cleaning after cloudbase-init ..."
Stop-Service "cloudbase-init" -Force
Get-Process "python" | Stop-Process -Force
Remove-Item "C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\cloudbase-init.log" -Force

Write-Host "Delayed start for service cloude-init"
& "sc.exe" config "cloudbase-init" start= delayed-auto

Write-Host "Zeroing free space ..."
& "C:\Program Files (x86)\Sysinternals Suite\sdelete" -z /accepteula


Write-Host "Sysprepping image ..."
& C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Murano\Files\ws-2012-std\unattend.xml
