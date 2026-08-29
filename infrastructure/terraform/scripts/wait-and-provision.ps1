#Requires -Version 5.0
$ErrorActionPreference = "Continue" # Permet d'éviter que les warnings stderr de ssh ne fassent planter le script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$VmName     = $env:VM_NAME
$ScriptPath = $env:SCRIPT_PATH
$SshUser    = $env:SSH_USER
if (-not $SshUser) { $SshUser = "vagrant" }

$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $VBoxManage)) {
    $VBoxManage = "VBoxManage"
}

$KeyDir  = Join-Path $PSScriptRoot ".ssh"
$KeyPath = Join-Path $KeyDir "vagrant_insecure"

if (-not (Test-Path $KeyDir)) {
    New-Item -ItemType Directory -Path $KeyDir | Out-Null
}

if (-not (Test-Path $KeyPath)) {
    Write-Error "Clé SSH Vagrant introuvable : $KeyPath"
    exit 1
}

Write-Host ">>> Attente de l'adresse IP de la VM '$VmName' (sous-reseau host-only 192.168.56.0/24)..."
$Ip = $null
for ($i = 0; $i -lt 60; $i++) {
    try {
        $countRaw = & $VBoxManage guestproperty get $VmName "/VirtualBox/GuestInfo/Net/Count" 2>$null
        $count = 1
        if ($countRaw -match "Value:\s*(\d+)") { $count = [int]$Matches[1] }

        for ($idx = 0; $idx -lt $count; $idx++) {
            $raw = & $VBoxManage guestproperty get $VmName "/VirtualBox/GuestInfo/Net/$idx/V4/IP" 2>$null
            if ($raw -match "Value:\s*(\d+\.\d+\.\d+\.\d+)") {
                $candidate = $Matches[1]
                if ($candidate.StartsWith("192.168.56.")) {
                    $Ip = $candidate
                    break
                }
            }
        }
        if ($Ip) { break }
    } catch {
    }
    Start-Sleep -Seconds 10
}

if (-not $Ip) {
    Write-Error "Impossible d'obtenir l'IP de '$VmName' apres 10 minutes."
    exit 1
}

Write-Host ">>> IP obtenue pour '$VmName' : $Ip"

# Configuration SSH silencieuse pour éliminer tout warning sur stderr
$SshOpts = @(
    "-i", $KeyPath,
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=NUL",
    "-o", "LogLevel=ERROR",
    "-o", "ConnectTimeout=10"
)

Write-Host ">>> Attente que le service SSH soit pret sur $Ip..."
$SshReady = $false
for ($i = 0; $i -lt 30; $i++) {
    # Neutralisation de la capture d'erreur NativeCommandError de PowerShell
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    
    $test = & ssh @SshOpts "$SshUser@$Ip" "echo ok" 2>&1
    
    $ErrorActionPreference = $oldPreference

    if ($test -match "ok") { 
        $SshReady = $true
        break 
    }
    Start-Sleep -Seconds 10
}

if (-not $SshReady) {
    Write-Error "SSH ne repond pas sur $Ip apres plusieurs tentatives."
    exit 1
}

$RemoteScriptName = Split-Path $ScriptPath -Leaf

Write-Host ">>> Copie du script de provisioning vers la VM..."
& scp @SshOpts $ScriptPath "${SshUser}@${Ip}:/tmp/$RemoteScriptName"
if ($LASTEXITCODE -ne 0) { Write-Error "Echec de la copie (scp)."; exit 1 }

Write-Host ">>> Execution du script de provisioning sur la VM (peut prendre plusieurs minutes)..."
& ssh @SshOpts "$SshUser@$Ip" "chmod +x /tmp/$RemoteScriptName && sudo /tmp/$RemoteScriptName"
if ($LASTEXITCODE -ne 0) { Write-Error "Le script de provisioning a echoue sur la VM."; exit 1 }

Write-Host ">>> Provisioning de '$VmName' termine avec succes (IP: $Ip)."