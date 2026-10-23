# Flash a spare MikroTik as a travel router and register it on Kuca.
# Dry-run unless -Apply is passed. -Apply still stops for -Confirmed and -ConfirmedBoard.
# -Rollback undoes the gitignored journal from the last apply.
#
#   powershell -ExecutionPolicy Bypass -File scripts/flash_roaming_mikrotik.ps1 -Config .cursor/secrets/roaming-flash.json
#   powershell -ExecutionPolicy Bypass -File scripts/flash_roaming_mikrotik.ps1 -Config .cursor/secrets/roaming-flash.json -Apply -Confirmed
#   powershell -ExecutionPolicy Bypass -File scripts/flash_roaming_mikrotik.ps1 -Config .cursor/secrets/roaming-flash.json -Rollback

param(
    [string]$Config = '',
    [switch]$Apply,
    [switch]$Rollback,
    [switch]$Confirmed,
    [switch]$ConfirmedBoard,
    [switch]$ReflashLive,
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'roaming\RoamingFlash.ps1')

$repoRoot = Get-RoamingRepoRoot
if (-not $Config) {
    $Config = Join-Path $repoRoot '.cursor\secrets\roaming-flash.json'
}
$kucaSecretPath = Join-Path $repoRoot '.cursor\secrets\.router-kuca'
$mostarSecretPath = Join-Path $repoRoot '.cursor\secrets\.router-mostar'
$outDir = Join-Path $repoRoot 'infrastructure\roaming\out'

function New-RosSecureString {
    param([AllowEmptyString()][string]$Plain)
    $secure = New-Object System.Security.SecureString
    foreach ($char in ([string]$Plain).ToCharArray()) { $secure.AppendChar($char) }
    return $secure
}

function Assert-PoshSsh {
    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        throw 'Posh-SSH is not installed. The flash stops here and does not use sshpass.'
    }
    Import-Module Posh-SSH -ErrorAction Stop
}

function Connect-RosSession {
    param($Endpoint, [switch]$AcceptNewKey)
    Assert-PoshSsh
    $credential = New-Object System.Management.Automation.PSCredential ([string]$Endpoint.Username, (New-RosSecureString $Endpoint.Password))
    if ($AcceptNewKey) {
        return (New-SSHSession -ComputerName $Endpoint.IP -Credential $credential -AcceptKey -ConnectionTimeout 15 -ErrorAction Stop)
    }
    return (New-SSHSession -ComputerName $Endpoint.IP -Credential $credential -ConnectionTimeout 15 -ErrorAction Stop)
}

function Invoke-RosCommand {
    param($Session, [Parameter(Mandatory = $true)][string]$Command)
    $result = Invoke-SSHCommand -SessionId $Session.SessionId -Command $Command -TimeOut 60 -ErrorAction Stop
    $text = @($result.Output) -join "`n"
    $errorText = @($result.Error) -join "`n"
    if ($errorText -match 'failure|syntax error|expected') {
        throw "RouterOS command failed. The command text is not repeated because it may contain a secret."
    }
    return $text
}

function Close-RosSession {
    param($Session)
    if ($Session) {
        Remove-SSHSession -SessionId $Session.SessionId -ErrorAction SilentlyContinue | Out-Null
    }
}

function Read-Endpoint {
    param([string]$Path)
    $map = Read-KeyValueSecret -Path $Path
    if (-not $map.IP -or -not $map.Username) { throw "Secret file is missing IP or Username." }
    return [pscustomobject]@{ IP = $map.IP; Username = $map.Username; Password = [string]$map.Password }
}

function Get-KucaSnapshot {
    param($Session)
    $secretText = Invoke-RosCommand -Session $Session -Command '/ppp secret print terse proplist=name,remote-address,service'
    $routeText = Invoke-RosCommand -Session $Session -Command '/ip route print terse proplist=dst-address,gateway,comment'
    $addressText = Invoke-RosCommand -Session $Session -Command '/ip address print terse proplist=address'
    $listText = Invoke-RosCommand -Session $Session -Command '/ip firewall address-list print terse proplist=list,address,comment'
    $activeText = Invoke-RosCommand -Session $Session -Command '/ppp active print terse proplist=name,address'
    $profileText = Invoke-RosCommand -Session $Session -Command '/ppp profile print terse proplist=name,remote-address'
    $poolText = Invoke-RosCommand -Session $Session -Command '/ip pool print terse proplist=name,ranges'
    $serviceText = Invoke-RosCommand -Session $Session -Command '/ip service print terse proplist=name,address'
    $ipsecText = Invoke-RosCommand -Session $Session -Command '/interface l2tp-server server print terse proplist=ipsec-secret'
    $identityText = Invoke-RosCommand -Session $Session -Command '/system identity print terse proplist=name'
    $serialText = Invoke-RosCommand -Session $Session -Command '/system routerboard print terse proplist=serial-number'
    $keyText = Invoke-RosCommand -Session $Session -Command ':foreach i in=[/user ssh-keys find where user=admin] do={ :put [/user ssh-keys get $i key] }'

    $ipsec = ''
    foreach ($row in @(ConvertFrom-RosTerse $ipsecText)) {
        if ($row.ContainsKey('ipsec-secret')) { $ipsec = [string]$row['ipsec-secret'] }
    }
    $keys = @($keyText -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -like 'ssh-*' })
    $services = @{}
    foreach ($row in @(ConvertFrom-RosTerse $serviceText)) {
        if ($row.name) { $services[$row.name] = [string]$row.address }
    }
    $profiles = @()
    foreach ($row in @(ConvertFrom-RosTerse $profileText)) {
        $profiles += [pscustomobject]@{ Name = [string]$row.name; Remote = [string]$row.'remote-address' }
    }
    $pools = @()
    foreach ($row in @(ConvertFrom-RosTerse $poolText)) {
        $pools += [pscustomobject]@{ Name = [string]$row.name; Ranges = [string]$row.ranges }
    }
    return [pscustomobject]@{
        Secrets      = @(ConvertFrom-RosTerse $secretText | ForEach-Object { [pscustomobject]@{ Name = [string]$_.name; Remote = [string]$_.'remote-address'; Service = [string]$_.service } })
        Routes       = @(ConvertFrom-RosTerse $routeText | ForEach-Object { [pscustomobject]@{ Dst = [string]$_.'dst-address'; Gateway = [string]$_.gateway; Comment = [string]$_.comment } })
        Addresses    = @(ConvertFrom-RosTerse $addressText | ForEach-Object { [string]$_.address })
        AddressLists = @(ConvertFrom-RosTerse $listText | ForEach-Object { [pscustomobject]@{ List = [string]$_.list; Address = [string]$_.address; Comment = [string]$_.comment } })
        Active       = @(ConvertFrom-RosTerse $activeText | ForEach-Object { [string]$_.address })
        Profiles     = @($profiles)
        Pools        = @($pools)
        Services     = $services
        Identity     = [string](@(ConvertFrom-RosTerse $identityText) | Select-Object -First 1).name
        Serial       = [string](@(ConvertFrom-RosTerse $serialText) | Select-Object -First 1).'serial-number'
        SshKeys      = @($keys)
        IpsecSecret  = $ipsec
    }
}

function Get-TakenVpnAddresses {
    param($Snapshot)
    $taken = New-Object System.Collections.Generic.List[string]
    foreach ($secret in @($Snapshot.Secrets)) { if ($secret.Remote) { $taken.Add($secret.Remote) } }
    foreach ($address in @($Snapshot.Addresses)) { if ($address) { $taken.Add($address) } }
    foreach ($route in @($Snapshot.Routes)) { if ($route.Gateway) { $taken.Add($route.Gateway) } }
    foreach ($active in @($Snapshot.Active)) { if ($active) { $taken.Add($active) } }
    return @($taken)
}

function Get-ProfilePoolRanges {
    param($Snapshot)
    $profile = @($Snapshot.Profiles) | Where-Object { $_.Name -eq 'mostardesigns.com l2tp' } | Select-Object -First 1
    if (-not $profile -or -not $profile.Remote) {
        return [pscustomobject]@{ Name = ''; Ranges = @() }
    }
    if ($profile.Remote -match '^\d{1,3}(\.\d{1,3}){3}$') {
        return [pscustomobject]@{ Name = ''; Ranges = @() }
    }
    $pool = @($Snapshot.Pools) | Where-Object { $_.Name -eq $profile.Remote } | Select-Object -First 1
    $ranges = @()
    if ($pool) { $ranges = @($pool.Ranges) }
    return [pscustomobject]@{ Name = [string]$profile.Remote; Ranges = $ranges }
}

if ($Rollback) {
    if (-not (Test-Path -LiteralPath $Config)) { throw "Config not found: $Config" }
    $rawRollback = Get-Content -Raw -LiteralPath $Config | ConvertFrom-Json
    $rollbackConfig = Resolve-RoamingConfig -Raw $rawRollback
    $journalFile = Join-Path $outDir ("kuca-journal-{0}.json" -f $rollbackConfig.Slug)
    if (-not (Test-Path -LiteralPath $journalFile)) {
        throw "No journal at $journalFile. There is nothing to roll back."
    }
    $journal = Get-Content -Raw -LiteralPath $journalFile | ConvertFrom-Json
    $commands = @(Get-KucaRollbackCommands $journal)
    if ($Offline) {
        Write-Output "Rollback is offline. Reconnect this PC to the house, then run -Rollback without -Offline."
        Write-Output ("commands: {0}" -f $commands.Count)
        exit 0
    }
    $kuca = Read-Endpoint -Path $kucaSecretPath
    $session = Connect-RosSession -Endpoint $kuca
    try {
        foreach ($command in $commands) {
            Invoke-RosCommand -Session $session -Command (":do { $command } on-error={}") | Out-Null
        }
    }
    finally { Close-RosSession $session }
    Remove-Item -LiteralPath $journalFile -Force
    Write-Output "Rollback finished and the journal was removed."
    exit 0
}

if (-not (Test-Path -LiteralPath $Config)) {
    throw "Config not found. Copy infrastructure/roaming/roaming.example.json to .cursor/secrets/roaming-flash.json and fill it in."
}
$raw = Get-Content -Raw -LiteralPath $Config | ConvertFrom-Json
$resolved = Resolve-RoamingConfig -Raw $raw -RequireSecrets:$Apply
if (-not $Apply -and (-not $resolved.WifiPassword -or -not $resolved.AdminPassword -or -not $resolved.IpsecSecret)) {
    throw "The secrets file still has empty wifiPassword, adminPassword, or l2tp.ipsecSecret."
}

$inventoryText = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'infrastructure\networks.md')
$blocked = @(Get-HotelAndFactoryBlocks) + @(Get-InventoryCidrs $inventoryText)
if ($ReflashLive) {
    $blocked = @($blocked | Where-Object { $_ -ne '192.168.86.0/24' })
}
$lanCheck = Test-LanAllowed -LanCidr $resolved.Lan.Cidr -Blocked $blocked -OtherCidr $resolved.Local.Cidr
if (-not $lanCheck.Allowed) { throw "VPN LAN $($resolved.Lan.Cidr) $($lanCheck.Reason)." }
$localCheck = Test-LanAllowed -LanCidr $resolved.Local.Cidr -Blocked $blocked -OtherCidr $resolved.Lan.Cidr
if (-not $localCheck.Allowed) { throw "Local LAN $($resolved.Local.Cidr) $($localCheck.Reason)." }

$deny = Get-DefaultDenyList
$snapshot = $null
$ipsecResult = 'unchecked'
$keyCount = 0
$vpnPick = $null
$poolNote = 'not read'
$writePassword = $false

if ($Offline) {
    $generated = Resolve-L2tpPassword -Existing $resolved.L2tpPassword
    if ($generated -ne $resolved.L2tpPassword) { $writePassword = $true }
    $resolved | Add-Member -NotePropertyName L2tpPassword -NotePropertyValue $generated -Force
    $vpnPick = Select-VpnAddress -Taken @() -PoolRanges @() -PoolName ''
    $poolNote = 'offline'
}
else {
    Assert-PoshSsh
    $kuca = Read-Endpoint -Path $kucaSecretPath
    $kucaSession = Connect-RosSession -Endpoint $kuca
    try {
        $snapshot = Get-KucaSnapshot -Session $kucaSession
    }
    finally { Close-RosSession $kucaSession }
    $deny = Merge-DenyList -Base $deny -Extra ([pscustomobject]@{
            Identities = @($snapshot.Identity)
            Serials    = @($snapshot.Serial)
        })
    if (Test-Path -LiteralPath $mostarSecretPath) {
        $mostar = Read-Endpoint -Path $mostarSecretPath
        $mostarSession = Connect-RosSession -Endpoint $mostar
        try {
            $mostarIdentity = Invoke-RosCommand -Session $mostarSession -Command '/system identity print terse proplist=name'
            $mostarSerial = Invoke-RosCommand -Session $mostarSession -Command '/system routerboard print terse proplist=serial-number'
        }
        finally { Close-RosSession $mostarSession }
        $deny = Merge-DenyList -Base $deny -Extra ([pscustomobject]@{
                Identities = @([string](@(ConvertFrom-RosTerse $mostarIdentity) | Select-Object -First 1).name)
                Serials    = @([string](@(ConvertFrom-RosTerse $mostarSerial) | Select-Object -First 1).'serial-number')
            })
    }
    $ipsecResult = Test-IpsecSecret -ServerSecret $snapshot.IpsecSecret -ConfigSecret $resolved.IpsecSecret
    $snapshot.IpsecSecret = $null
    if ($ipsecResult -ne 'match') { throw 'IPsec secret mismatch. The server secret was not changed.' }
    $keyCount = @($snapshot.SshKeys).Count
    if ($Apply -and $keyCount -ne 2) { throw "Kuca admin has $keyCount SSH keys. The flash stops before any reset because it needs exactly two." }
    $existingSecret = @($snapshot.Secrets) | Where-Object { $_.Name -eq $resolved.L2tpUsername } | Select-Object -First 1
    $existingRemote = ''
    if ($existingSecret) { $existingRemote = [string]$existingSecret.Remote }
    $pool = Get-ProfilePoolRanges -Snapshot $snapshot
    $vpnPick = Select-VpnAddress -ExistingRemote $existingRemote -Taken (Get-TakenVpnAddresses $snapshot) -PoolRanges $pool.Ranges -PoolName $pool.Name
    $poolNote = $pool.Name
    if (-not $resolved.L2tpPassword) {
        $resolved | Add-Member -NotePropertyName L2tpPassword -NotePropertyValue (New-L2tpPassword) -Force
        $writePassword = $true
    }
}

if ($vpnPick.Stopped) {
    throw "No free VPN address outside the L2TP pool. Pool: $($vpnPick.Pool)"
}
$planDeny = Test-PlanUsesLiveRouter -Name $resolved.Name -Username $resolved.L2tpUsername -LanCidr $resolved.Lan.Cidr -VpnAddress $vpnPick.Address -DenyList $deny -ReflashLive:$ReflashLive
if (-not $planDeny.Allowed) { throw $planDeny.Reason }

Write-Output (Format-RoamingPlan -Config $resolved -VpnAddress $vpnPick.Address -IpsecResult $ipsecResult -KeyCount $keyCount -PoolNote $poolNote)

$stage = Get-ApplyStage -Apply:$Apply -Confirmed:$Confirmed -ConfirmedBoard:$ConfirmedBoard -OnLink:$false
if ($stage -eq 'dry-run') {
    Write-Output 'Dry-run only. Pass -Apply -Confirmed to register this router on Kuca.'
    exit 0
}
if ($stage -eq 'need-kuca-confirm') {
    Write-Output 'Kuca was not changed. Pass -Apply -Confirmed after you accept the name, subnet, secret, and VPN address above.'
    exit 2
}

if ($writePassword) {
    $raw.l2tp.password = $resolved.L2tpPassword
    $saved = $raw | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $Config -Value $saved -Encoding utf8
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$journalFile = Join-Path $outDir ("kuca-journal-{0}.json" -f $resolved.Slug)
if (-not $snapshot) { throw 'Kuca was not read, so nothing can be written.' }
$change = Build-KucaChangeSet -Config $resolved -VpnAddress $vpnPick.Address -Snapshot $snapshot -WritePassword:$writePassword
$change.Journal | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $journalFile -Encoding utf8
$kuca = Read-Endpoint -Path $kucaSecretPath
$writeSession = Connect-RosSession -Endpoint $kuca
try {
    foreach ($command in @($change.Commands)) {
        Invoke-RosCommand -Session $writeSession -Command $command | Out-Null
    }
}
finally { Close-RosSession $writeSession }
Write-Output "Kuca registration is journaled at $journalFile."
Write-Output 'Cable a LAN port of the new board to this PC, then rerun with -Apply -Confirmed -ConfirmedBoard.'

if (-not $ConfirmedBoard) { exit 0 }

$onLink = Test-OnLinkFactoryBoard -LocalAddresses @(
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{ Ip = $_.IPAddress; Prefix = [int]$_.PrefixLength; InterfaceAlias = $_.InterfaceAlias }
    }
) -ArpEntries @(
    Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{ Ip = $_.IPAddress; InterfaceAlias = $_.InterfaceAlias; State = [string]$_.State }
    }
)
if (-not $onLink.Found) {
    throw "192.168.88.1 is not on-link. A routed answer can be Mostar. Cable a LAN port to this PC, or run -Rollback after reconnecting to the house. Journal: $journalFile"
}

$factory = [pscustomobject]@{
    IP       = '192.168.88.1'
    Username = 'admin'
    Password = $resolved.FactoryPassword
}
$boardSession = Connect-RosSession -Endpoint $factory -AcceptNewKey
try {
    $shell = New-SSHShellStream -SessionId $boardSession.SessionId
    Start-Sleep -Seconds 1
    $banner = $shell.Read()
    if ($banner -match 'new password|Change your password') {
        $shell.WriteLine($resolved.AdminPassword)
        Start-Sleep -Milliseconds 400
        $shell.WriteLine($resolved.AdminPassword)
        Start-Sleep -Seconds 1
    }
    $identityText = Invoke-RosCommand -Session $boardSession -Command '/system identity print terse proplist=name'
    $serialText = Invoke-RosCommand -Session $boardSession -Command '/system routerboard print terse proplist=serial-number'
    $versionText = Invoke-RosCommand -Session $boardSession -Command '/system resource print terse proplist=version'
    $packageText = Invoke-RosCommand -Session $boardSession -Command '/system package print terse proplist=name'
    $wirelessText = Invoke-RosCommand -Session $boardSession -Command ':do { /interface wireless print terse proplist=name,default-name } on-error={}'
    $wifiText = Invoke-RosCommand -Session $boardSession -Command ':do { /interface wifi print terse proplist=name,default-name } on-error={}'
}
finally { Close-RosSession $boardSession }

$boardIdentity = [string](@(ConvertFrom-RosTerse $identityText) | Select-Object -First 1).name
$boardSerial = [string](@(ConvertFrom-RosTerse $serialText) | Select-Object -First 1).'serial-number'
$boardVersion = [string](@(ConvertFrom-RosTerse $versionText) | Select-Object -First 1).version
$boardDeny = Test-BoardDenied -Identity $boardIdentity -Serial $boardSerial -DenyList $deny
if ($boardDeny.Denied) {
    throw "This board is on the denylist ($($boardDeny.Reason)). It was not reset. Reconnect to the house and run -Rollback. Journal: $journalFile"
}
$version = Test-RouterOsVersion $boardVersion
if (-not $version.Ok) {
    throw ($version.Message + " The board was not reset. Reconnect to the house and run -Rollback. Journal: $journalFile")
}
$package = Get-WirelessPackageChoice -WirelessPrint $wirelessText -WifiPrint $wifiText
if (-not $package) {
    if ($packageText -match 'wireless') { $package = 'wireless' }
    elseif ($packageText -match 'wifi') { $package = 'wifi' }
}
if (-not $package) {
    throw "This board has no wireless or wifi package. It was not reset. Reconnect to the house and run -Rollback."
}
Write-Output "board: $boardIdentity serial=$boardSerial version=$boardVersion package=$package"
Write-Output 'Second confirmation accepted. Resetting this board only.'

$secondRadio = ''
if ($package -eq 'wireless' -and $wirelessText -match 'wlan2') { $secondRadio = 'wlan2' }
if ($package -eq 'wifi' -and $wifiText -match 'wifi2') { $secondRadio = 'wifi2' }
$rsc = New-RoamingRsc -Config $resolved -Package $package -SshKeys $snapshot.SshKeys -SecondRadioName $secondRadio
$rscPath = Join-Path $outDir 'flash.rsc'
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($rscPath, $rsc, $utf8)

Assert-PoshSsh
$upload = Connect-RosSession -Endpoint $factory -AcceptNewKey
try {
    Set-SCPItem -ComputerName $factory.IP -Credential (New-Object System.Management.Automation.PSCredential ($factory.Username, (New-RosSecureString $factory.Password))) -Path $rscPath -Destination '/' -AcceptKey -ErrorAction Stop
    Invoke-RosCommand -Session $upload -Command '/system reset-configuration no-defaults=yes skip-backup=yes run-after-reset=flash.rsc' | Out-Null
}
finally { Close-RosSession $upload }

$deadline = (Get-Date).AddSeconds(180)
$reached = $false
while ((Get-Date) -lt $deadline) {
    & ipconfig.exe /renew "$($onLink.InterfaceAlias)" | Out-Null
    Start-Sleep -Seconds 5
    $have = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $onLink.InterfaceAlias -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like ("{0}.*" -f ($resolved.Lan.Network.Substring(0, $resolved.Lan.Network.LastIndexOf('.')))) }
    if ($have) { $reached = $true; break }
}
if (-not $reached) {
    throw "The board did not come back on $($resolved.Lan.Cidr) within 180 seconds. Reconnect to the house and run -Rollback if registration should be removed. Journal: $journalFile"
}

$admin = [pscustomobject]@{ IP = $resolved.Lan.Gateway; Username = 'admin'; Password = $resolved.AdminPassword }
$check = Connect-RosSession -Endpoint $admin -AcceptNewKey
try {
    $logText = Invoke-RosCommand -Session $check -Command '/log print terse proplist=message where message~"roaming-flash"'
    if ($logText -match 'did not appear|Script error|syntax error') {
        Invoke-RosCommand -Session $check -Command '/file remove [find where name="flash.rsc"]' | Out-Null
        throw "The import logged a script error. flash.rsc was removed if it was still on the board. Journal: $journalFile"
    }
    Invoke-RosCommand -Session $check -Command '/file remove [find where name="flash.rsc"]' | Out-Null
    $seenIdentity = Invoke-RosCommand -Session $check -Command '/system identity print terse proplist=name'
    $seenL2tp = Invoke-RosCommand -Session $check -Command '/interface l2tp-client print terse proplist=name,disabled,user'
    $seenKeys = Invoke-RosCommand -Session $check -Command '/user ssh-keys print count-only where user=admin'
}
finally { Close-RosSession $check }
Write-Output ("identity-now: {0}" -f ([string](@(ConvertFrom-RosTerse $seenIdentity) | Select-Object -First 1).name))
Write-Output ("l2tp: {0}" -f ($seenL2tp -replace '\s+', ' '))
Write-Output ("admin-keys-on-board: {0}" -f $seenKeys.Trim())
Write-Output 'Flash finished. Guest Wi-Fi is joined later with the join-guest script.'
