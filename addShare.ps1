[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$Storage_account_name,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$Storage_account_key,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$File_share_name
)

Write-Output "$Storage_account_name.file.core.windows.net"

$connectTestResult = Test-NetConnection -ComputerName "$Storage_account_name.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$Storage_account_name.file.core.windows.net`" /user:`"localhost\$Storage_account_name`" /pass:`"$Storage_account_key`""
    # Mount the drive
    New-PSDrive -Name X -PSProvider FileSystem -Root "\\$Storage_account_name.file.core.windows.net\$File_share_name" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}