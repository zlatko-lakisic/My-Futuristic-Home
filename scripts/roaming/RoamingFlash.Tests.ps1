$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RoamingFlash.ps1')

$failures = New-Object System.Collections.Generic.List[string]
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $script:failures.Add($Message) }
}
function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -ne $Expected) { $script:failures.Add("$Message (expected '$Expected', got '$Actual')") }
}

$keys = @(
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyOne fixture-one',
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQTestKeyTwo fixture-two'
)

function New-TestRaw {
    param([string]$Name = 'Trip', [string]$Lan = '10.50.0.0', [string]$Password = 'stored-secret')
    return [pscustomobject]@{
        name              = $Name
        wifiPassword      = 'wifi-secret'
        localWifiPassword = ''
        adminPassword     = 'admin-secret'
        factoryPassword   = ''
        lanNetwork        = $Lan
        prefixLength      = 24
        localNetwork      = '172.31.250.0'
        localPrefixLength = 24
        country           = 'united states'
        homeNetworks      = @('192.168.89.0/24', '10.0.10.0/24', '172.16.90.0/24')
        managementExtra   = @('192.168.90.0/24')
        l2tp              = [pscustomobject]@{
            server       = 'nyc.mostardesigns.com'
            username     = ''
            password     = $Password
            ipsecSecret  = 'ipsec-secret'
        }
    }
}

$lan = Get-LanPlan -Network '10.50.0.0' -PrefixLength 24
Assert-Equal $lan.Gateway '10.50.0.1' 'gateway'
Assert-Equal $lan.Pool '10.50.0.2-10.50.0.254' 'pool endpoints'
$threw = $false
try { Get-LanPlan -Network '192.168.87.0' -PrefixLength 23 | Out-Null } catch { $threw = $true }
Assert-True $threw 'unaligned prefix is rejected'

$hotel = Test-LanAllowed -LanCidr '192.168.1.0/24' -Blocked (Get-HotelAndFactoryBlocks)
Assert-True (-not $hotel.Allowed) 'hotel range is rejected'
$factoryNet = Test-LanAllowed -LanCidr '192.168.88.0/24' -Blocked (Get-HotelAndFactoryBlocks)
Assert-True (-not $factoryNet.Allowed) 'factory and Mostar range is rejected'
$okLan = Test-LanAllowed -LanCidr '10.50.0.0/24' -Blocked (Get-HotelAndFactoryBlocks)
Assert-True $okLan.Allowed 'unrelated LAN is allowed'
Assert-True (Test-CidrOverlap -Left '10.50.0.0/23' -Right '10.50.1.0/24') 'overlapping prefixes are detected'

$inventory = Get-InventoryCidrs "# sample`n| ``192.168.89.0/24`` | home |"
Assert-True (@($inventory) -contains '192.168.89.0/24') 'inventory parser reads networks.md style prefixes'

$fullPool = Select-VpnAddress -Taken @('172.16.91.25', '172.16.91.30') -PoolRanges @('172.16.91.2-172.16.91.29') -PoolName 'vpn_pool'
Assert-True $fullPool.Stopped 'address picker stops when the pool covers every free host'
Assert-True ($fullPool.Pool -like '*172.16.91.2-172.16.91.29*') 'stopped picker names the pool'
$openPool = Select-VpnAddress -Taken @('172.16.91.25', '172.16.91.30') -PoolRanges @() -PoolName ''
Assert-Equal $openPool.Address '172.16.91.3' 'no remote pool still returns the lowest free host'
$reused = Select-VpnAddress -ExistingRemote '172.16.91.25' -Taken @('172.16.91.25') -PoolRanges @('172.16.91.2-172.16.91.29') -PoolName 'vpn_pool'
Assert-True $reused.Reused 'existing secret keeps its address'
Assert-Equal $reused.Address '172.16.91.25' 'reused address'

$stored = Resolve-L2tpPassword -Existing 'stored-secret'
Assert-Equal $stored 'stored-secret' 'stored L2TP password is reused'
$generated = Resolve-L2tpPassword -Existing ''
Assert-True ($generated.Length -ge 16) 'missing password is generated'
Assert-Equal (Resolve-L2tpPassword -Existing $generated) $generated 'a later resolve returns the same password'

Assert-Equal (Test-IpsecSecret -ServerSecret 'same' -ConfigSecret 'same') 'match' 'matching ipsec'
Assert-Equal (Test-IpsecSecret -ServerSecret 'same' -ConfigSecret 'other') 'mismatch' 'different ipsec'
Assert-True (-not (Test-RouterOsVersion '6.49.6').Ok) 'RouterOS 6 is below the floor'
Assert-True ((Test-RouterOsVersion '6.49.6').Message -like '*routeros-smips*') 'upgrade message names the hAP ac lite package'
Assert-True (Test-RouterOsVersion '7.15').Ok '7.15 is the floor'
Assert-True (Test-RouterOsVersion '7.15.2').Ok 'newer than the floor is accepted'
Assert-True (-not (Test-RouterOsVersion '7.14.3').Ok) '7.14 is refused'

$live = Test-PlanUsesLiveRouter -Name 'Kuca' -Username 'l2tp-roaming-kuca' -LanCidr '192.168.86.0/24' -VpnAddress '172.16.91.25'
Assert-True (-not $live.Allowed) 'live Kuca-Roaming values are refused'
$again = Test-PlanUsesLiveRouter -Name 'Kuca' -Username 'l2tp-roaming-kuca' -LanCidr '192.168.86.0/24' -VpnAddress '172.16.91.25' -ReflashLive
Assert-True $again.Allowed 'reflash flag allows those registration values'
$serialHit = Test-BoardDenied -Serial '628105BB1449' -Identity 'MikroTik'
Assert-True $serialHit.Denied 'live roaming serial is always denied'
Assert-True (-not (Test-BoardDenied -Serial 'AABBCCDDEEFF' -Identity 'MikroTik').Denied) 'an unknown board is not denied'

$on = Test-OnLinkFactoryBoard -LocalAddresses @([pscustomobject]@{ Ip = '192.168.88.10'; Prefix = 24; InterfaceAlias = 'Ethernet' }) -ArpEntries @([pscustomobject]@{ Ip = '192.168.88.1'; InterfaceAlias = 'Ethernet'; State = 'Reachable' })
Assert-True $on.Found 'on-link ARP is a find'
$routed = Test-OnLinkFactoryBoard -LocalAddresses @([pscustomobject]@{ Ip = '192.168.89.20'; Prefix = 24; InterfaceAlias = 'Ethernet' }) -ArpEntries @([pscustomobject]@{ Ip = '192.168.88.1'; InterfaceAlias = 'Ethernet'; State = 'Reachable' })
Assert-True (-not $routed.Found) 'a routed 192.168.88.1 is not a find'

Assert-Equal (Get-ApplyStage) 'dry-run' 'default stage is dry-run'
Assert-Equal (Get-ApplyStage -Apply) 'need-kuca-confirm' 'apply waits for confirmation'
Assert-Equal (Get-ApplyStage -Apply -Confirmed) 'kuca-written-need-board' 'kuca confirmation is not a reset'
Assert-Equal (Get-ApplyStage -Apply -Confirmed -ConfirmedBoard) 'need-on-link' 'reset waits for an on-link board'
Assert-Equal (Get-ApplyStage -Apply -Confirmed -ConfirmedBoard -OnLink) 'reset' 'reset is the last stage'

$trip = Resolve-RoamingConfig -Raw (New-TestRaw) -RequireSecrets
$cabin = Resolve-RoamingConfig -Raw (New-TestRaw -Name 'Cabin' -Lan '10.51.0.0') -RequireSecrets
Assert-Equal $trip.L2tpUsername 'l2tp-roaming-trip' 'secret name follows the router name'
Assert-True ($trip.L2tpUsername -ne $cabin.L2tpUsername) 'a second name gets a different secret'
$planText = Format-RoamingPlan -Config $trip -VpnAddress '172.16.91.6' -IpsecResult 'match' -KeyCount 2 -PoolNote 'vpn_pool'
Assert-True ($planText -notlike '*stored-secret*') 'plan text omits the L2TP password'
Assert-True ($planText -notlike '*admin-secret*') 'plan text omits the admin password'
Assert-True ($planText -notlike '*ipsec-secret*') 'plan text omits the IPsec secret'

$legacy = New-RoamingRsc -Config $trip -Package wireless -LanPorts @('ether2', 'ether3', 'ether4', 'ether5') -SshKeys $keys -SecondRadioName 'wlan2'
$wifi = New-RoamingRsc -Config $trip -Package wifi -LanPorts @('ether2', 'ether3', 'ether4', 'ether5') -SshKeys $keys -SecondRadioName 'wifi2'
$bridgeAt = $legacy.IndexOf('add name=nyc_bridge')
$portAt = $legacy.IndexOf('add bridge=nyc_bridge interface=ether2')
$listAt = $legacy.IndexOf('add interface=nyc_bridge list=LAN')
$addressAt = $legacy.IndexOf('/ip address')
$userAt = $legacy.IndexOf('set [find name=admin] password=')
$keyAt = $legacy.IndexOf('/user ssh-keys')
$macAt = $legacy.IndexOf('/tool mac-server mac-winbox')
Assert-True ($bridgeAt -ge 0 -and $bridgeAt -lt $portAt -and $portAt -lt $listAt -and $listAt -lt $addressAt -and $addressAt -lt $userAt -and $userAt -lt $keyAt -and $keyAt -lt $macAt) 'bridge, ports, and LAN list come before the address, password, keys, and MAC Winbox'
Assert-True ($legacy -like '*name=join-guest*') 'legacy file has join-guest'
Assert-True ($legacy -like '*roaming-local-masquerade*') 'local subnet is masqueraded'
Assert-True ($legacy -like '*172.31.250.0/24*') 'local subnet is present'
$mangle = @($legacy -split "`n" | Where-Object { $_ -like '*mark-routing*' })
Assert-True ($mangle.Count -eq 1 -and $mangle[0] -notlike '*172.31.250.0/24*') 'local subnet is absent from the via_nyc mark'
Assert-True ($legacy -notlike '*wireguard*') 'legacy file has no WireGuard'
Assert-True ($legacy -notlike '*cfg-station*') 'legacy file has no wifi mode configuration'
Assert-True ($legacy -like '*default-name=wlan2*') 'hAP ac lite second radio is wlan2'
Assert-True ($wifi -like '*name=roaming-wifi-mode*') 'wifi file has the mode switch'
Assert-True ($wifi -like '*default-name=wifi2*') 'wifi second radio uses wifi2'
$isp = Get-IspScriptSource -HomeNetworks $trip.HomeNetworks
Assert-True ($isp -like '*192.168.89.0/24*') 'at-home list is in the uplink script'
Assert-True ($isp -notlike '*192.168.90.0/24*') 'house Wi-Fi is not an at-home prefix'
Assert-True ($legacy -like '*192.168.90.0/24*') 'house Wi-Fi is allowed to manage the router'

$emptyServices = @{}
$threwEmpty = $false
try { Get-AppendedServiceAddress -Previous '' -Cidr '10.50.0.0/24' | Out-Null } catch { $threwEmpty = $true }
Assert-True $threwEmpty 'an empty service address is not replaced'
Assert-Equal (Get-AppendedServiceAddress -Previous '10.0.10.0/24' -Cidr '10.50.0.0/24') '10.0.10.0/24,10.50.0.0/24' 'service address is appended'

$snapshot = [pscustomobject]@{
    Secrets      = @()
    Routes       = @()
    AddressLists = @()
    Services     = @{ www = '10.0.10.0/24'; api = '10.0.10.0/24'; 'api-ssl' = '10.0.10.0/24' }
}
$created = Build-KucaChangeSet -Config $trip -VpnAddress '172.16.91.6' -Snapshot $snapshot -WritePassword
Assert-True (($created.Commands -join "`n") -like '*stored-secret*') 'a new secret is created with the stored password'
$againSnap = [pscustomobject]@{
    Secrets      = @([pscustomobject]@{ Name = 'l2tp-roaming-trip'; Remote = '172.16.91.6' })
    Routes       = @([pscustomobject]@{ Comment = 'roaming:trip'; Gateway = '172.16.91.6' })
    AddressLists = @(
        [pscustomobject]@{ List = 'support'; Address = '10.50.0.0/24' },
        [pscustomobject]@{ List = 'Local'; Address = '10.50.0.0/24' }
    )
    Services     = @{ www = '10.0.10.0/24,10.50.0.0/24'; api = '10.0.10.0/24,10.50.0.0/24'; 'api-ssl' = '10.0.10.0/24,10.50.0.0/24' }
}
$updated = Build-KucaChangeSet -Config $trip -VpnAddress '172.16.91.6' -Snapshot $againSnap
Assert-True (($updated.Commands -join "`n") -notlike '*stored-secret*') 'a rerun does not write the L2TP password again'

$journal = New-KucaJournal -Slug 'trip' -Username 'l2tp-roaming-trip' -LanCidr '10.50.0.0/24' -VpnAddress '172.16.91.6' -PreviousServices @{ www = '10.0.10.0/24'; api = '10.0.10.0/24'; 'api-ssl' = '10.0.10.0/24' }
$rollback = @(Get-KucaRollbackCommands $journal)
Assert-True ($rollback[0] -like '*api-ssl*' -and $rollback[0] -like '*10.0.10.0/24*') 'rollback restores the previous service address first'
Assert-True ($rollback[-1] -like '*ppp secret remove*') 'rollback removes the secret last'
Assert-True (($rollback -join "`n") -notlike '*pool set*') 'rollback does not touch the shared pool'

$rows = @(ConvertFrom-RosTerse "0 name=l2tp-roaming-trip password=SECRET remote-address=172.16.91.6 service=l2tp")
$projected = [pscustomobject]@{ Name = [string]$rows[0].name; Remote = [string]$rows[0].'remote-address'; Service = [string]$rows[0].service }
Assert-Equal $projected.Remote '172.16.91.6' 'terse parser reads the remote address'
Assert-True (@($projected.PSObject.Properties.Name) -notcontains 'password') 'projected secret drops the password field'

$example = Get-Content -Raw -LiteralPath (Join-Path (Get-RoamingRepoRoot) 'infrastructure\roaming\roaming.example.json') | ConvertFrom-Json
Assert-Equal $example.factoryPassword '' 'example sticker password may be blank'
Assert-Equal $example.name 'Kuca' 'example name is the live router'

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL: $_" }
    exit 1
}
Write-Output 'Roaming flash tests passed.'
exit 0
