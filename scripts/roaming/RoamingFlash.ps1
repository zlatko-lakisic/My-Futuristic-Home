# Pure helpers for the travel-router flash. No router I/O.
# The CLI in scripts/flash_roaming_mikrotik.ps1 dot-sources this file.

Set-StrictMode -Version 2.0

$script:VpnBase = '172.16.91.0'
$script:ReservedVpnOctets = @(0, 1, 2, 29, 30, 31)
$script:LiveRoamingSerial = '628105BB1449'
$script:VersionFloor = @(7, 15, 0)

function Get-RoamingRepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function ConvertTo-UInt32Address {
    param([Parameter(Mandatory = $true)][string]$Ip)
    $parsed = $null
    if (-not [System.Net.IPAddress]::TryParse($Ip, [ref]$parsed)) {
        throw "Not an IPv4 address: $Ip"
    }
    $bytes = $parsed.GetAddressBytes()
    if ($bytes.Length -ne 4) { throw "Not an IPv4 address: $Ip" }
    [array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function ConvertFrom-UInt32Address {
    param([Parameter(Mandatory = $true)][uint32]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    [array]::Reverse($bytes)
    return (New-Object System.Net.IPAddress -ArgumentList (, [byte[]]$bytes)).ToString()
}

function Get-Ipv4Mask {
    param([Parameter(Mandatory = $true)][int]$Prefix)
    if ($Prefix -le 0) { return [uint32]0 }
    if ($Prefix -ge 32) { return [uint32]4294967295 }
    $hostBits = 32 - $Prefix
    return [uint32](([uint64]4294967295 -shl $hostBits) -band [uint64]4294967295)
}

function Get-Ipv4Network {
    param(
        [Parameter(Mandatory = $true)][string]$Address,
        [Parameter(Mandatory = $true)][int]$Prefix
    )
    $ip = ConvertTo-UInt32Address $Address
    $mask = Get-Ipv4Mask $Prefix
    return [uint32]([uint64]$ip -band [uint64]$mask)
}

function Test-Ipv4Aligned {
    param(
        [Parameter(Mandatory = $true)][string]$Address,
        [Parameter(Mandatory = $true)][int]$Prefix
    )
    $ip = ConvertTo-UInt32Address $Address
    $network = Get-Ipv4Network -Address $Address -Prefix $Prefix
    return ($ip -eq $network)
}

function Add-Ipv4Offset {
    param(
        [Parameter(Mandatory = $true)][uint32]$Base,
        [Parameter(Mandatory = $true)][uint32]$Offset
    )
    return [uint32]([uint64]$Base + [uint64]$Offset)
}

function Get-CidrRange {
    param([Parameter(Mandatory = $true)][string]$Cidr)
    if ($Cidr -notmatch '^(\d{1,3}(?:\.\d{1,3}){3})/(\d{1,2})$') {
        throw "Not a CIDR: $Cidr"
    }
    $prefix = [int]$Matches[2]
    if ($prefix -lt 0 -or $prefix -gt 32) { throw "Prefix out of range: $Cidr" }
    $network = Get-Ipv4Network -Address $Matches[1] -Prefix $prefix
    $size = [uint32]1
    if ($prefix -lt 32) { $size = [uint32]([uint64]1 -shl (32 - $prefix)) }
    $broadcast = [uint32]([uint64]$network + [uint64]$size - 1)
    return [pscustomobject]@{
        Cidr      = ("{0}/{1}" -f (ConvertFrom-UInt32Address $network), $prefix)
        Network   = $network
        Broadcast = $broadcast
        Prefix    = $prefix
    }
}

function Test-CidrOverlap {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )
    $a = Get-CidrRange $Left
    $b = Get-CidrRange $Right
    return ($a.Network -le $b.Broadcast -and $b.Network -le $a.Broadcast)
}

function ConvertTo-NetworkCidr {
    param([Parameter(Mandatory = $true)][string]$AddressWithPrefix)
    if ($AddressWithPrefix -notmatch '^(\d{1,3}(?:\.\d{1,3}){3})/(\d{1,2})$') {
        return $null
    }
    $prefix = [int]$Matches[2]
    $network = Get-Ipv4Network -Address $Matches[1] -Prefix $prefix
    return "{0}/{1}" -f (ConvertFrom-UInt32Address $network), $prefix
}

function Get-LanPlan {
    param(
        [Parameter(Mandatory = $true)][string]$Network,
        [Parameter(Mandatory = $true)][int]$PrefixLength
    )
    if ($PrefixLength -lt 16 -or $PrefixLength -gt 29) {
        throw "Prefix length must be from 16 through 29. Got $PrefixLength."
    }
    if (-not (Test-Ipv4Aligned -Address $Network -Prefix $PrefixLength)) {
        throw "$Network/$PrefixLength is not aligned to that prefix."
    }
    $range = Get-CidrRange "$Network/$PrefixLength"
    $hostCount = [uint64]$range.Broadcast - [uint64]$range.Network + 1
    if ($hostCount -lt 4) { throw "Prefix /$PrefixLength has no DHCP pool." }
    $gateway = Add-Ipv4Offset -Base $range.Network -Offset 1
    $poolStart = Add-Ipv4Offset -Base $range.Network -Offset 2
    $poolEnd = [uint32]([uint64]$range.Broadcast - 1)
    return [pscustomobject]@{
        Cidr       = $range.Cidr
        Network    = ConvertFrom-UInt32Address $range.Network
        Prefix     = $PrefixLength
        Gateway    = ConvertFrom-UInt32Address $gateway
        Address    = ("{0}/{1}" -f (ConvertFrom-UInt32Address $gateway), $PrefixLength)
        PoolStart  = ConvertFrom-UInt32Address $poolStart
        PoolEnd    = ConvertFrom-UInt32Address $poolEnd
        Pool       = ("{0}-{1}" -f (ConvertFrom-UInt32Address $poolStart), (ConvertFrom-UInt32Address $poolEnd))
    }
}

function Get-HotelAndFactoryBlocks {
    return @(
        '192.168.88.0/24',
        '192.168.0.0/24',
        '192.168.1.0/24',
        '10.0.0.0/24'
    )
}

function Get-InventoryCidrs {
    param([string]$Markdown)
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($match in [regex]::Matches($Markdown, '\d{1,3}(?:\.\d{1,3}){3}/\d{1,2}')) {
        $cidr = ConvertTo-NetworkCidr $match.Value
        if ($cidr -and -not $found.Contains($cidr)) { $found.Add($cidr) }
    }
    return @($found)
}

function Test-LanAllowed {
    param(
        [Parameter(Mandatory = $true)][string]$LanCidr,
        [Parameter(Mandatory = $true)][string[]]$Blocked,
        [string]$OtherCidr
    )
    foreach ($block in $Blocked) {
        if ([string]::IsNullOrWhiteSpace($block)) { continue }
        if (Test-CidrOverlap -Left $LanCidr -Right $block) {
            return [pscustomobject]@{ Allowed = $false; Reason = "overlaps $block" }
        }
    }
    if ($OtherCidr -and (Test-CidrOverlap -Left $LanCidr -Right $OtherCidr)) {
        return [pscustomobject]@{ Allowed = $false; Reason = "overlaps $OtherCidr" }
    }
    return [pscustomobject]@{ Allowed = $true; Reason = '' }
}

function ConvertTo-RoamingSlug {
    param([Parameter(Mandatory = $true)][string]$Name)
    $slug = $Name.Trim().ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')
    if (-not $slug) { throw "Name '$Name' has no letters or digits." }
    return $slug
}

function Get-DefaultDenyList {
    return [pscustomobject]@{
        Identities   = @('Kuca', 'Kuca-Mostar', 'Kuca-Roaming')
        Serials      = @($script:LiveRoamingSerial)
        Macs         = @()
        Usernames    = @('l2tp-roaming-kuca')
        VpnAddresses = @('172.16.91.25')
        LanCidrs     = @('192.168.86.0/24')
    }
}

function Merge-DenyList {
    param($Base, $Extra)
    if (-not $Extra) { return $Base }
    foreach ($prop in @('Identities', 'Serials', 'Macs', 'Usernames', 'VpnAddresses', 'LanCidrs')) {
        $incoming = @($Extra.$prop)
        foreach ($item in $incoming) {
            if ($item -and (@($Base.$prop) -notcontains $item)) {
                $Base.$prop = @($Base.$prop) + $item
            }
        }
    }
    return $Base
}

function Test-PlanUsesLiveRouter {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Username,
        [Parameter(Mandatory = $true)][string]$LanCidr,
        [string]$VpnAddress,
        $DenyList = (Get-DefaultDenyList),
        [switch]$ReflashLive
    )
    $identity = "$Name-Roaming"
    $hits = New-Object System.Collections.Generic.List[string]
    if (@($DenyList.Identities) -contains $identity) { $hits.Add("identity $identity") }
    if (@($DenyList.Usernames) -contains $Username) { $hits.Add("username $Username") }
    foreach ($existing in @($DenyList.LanCidrs)) {
        if ($existing -and (Test-CidrOverlap -Left $LanCidr -Right $existing)) {
            $hits.Add("LAN $LanCidr overlaps $existing")
        }
    }
    if ($VpnAddress -and (@($DenyList.VpnAddresses) -contains $VpnAddress)) {
        $hits.Add("VPN address $VpnAddress")
    }
    if ($hits.Count -eq 0) {
        return [pscustomobject]@{ Allowed = $true; Reason = '' }
    }
    if ($ReflashLive) {
        return [pscustomobject]@{ Allowed = $true; Reason = '' }
    }
    return [pscustomobject]@{
        Allowed = $false
        Reason  = ("Refusing live-router values ({0}). Pass -ReflashLive only when you mean that router." -f ($hits -join ', '))
    }
}

function Test-BoardDenied {
    param(
        [string]$Identity,
        [string]$Serial,
        [string]$Mac,
        $DenyList = (Get-DefaultDenyList)
    )
    $hits = New-Object System.Collections.Generic.List[string]
    if ($Identity -and (@($DenyList.Identities) -contains $Identity)) { $hits.Add("identity $Identity") }
    if ($Serial -and (@($DenyList.Serials) -contains $Serial)) { $hits.Add("serial $Serial") }
    if ($Mac -and (@($DenyList.Macs) -contains $Mac)) { $hits.Add("MAC $Mac") }
    if ($hits.Count -eq 0) {
        return [pscustomobject]@{ Denied = $false; Reason = '' }
    }
    return [pscustomobject]@{ Denied = $true; Reason = ($hits -join ', ') }
}

function ConvertTo-VpnOctet {
    param([string]$Address)
    if (-not $Address) { return $null }
    $bare = ($Address -split '/')[0]
    if ($bare -notmatch '^172\.16\.91\.(\d+)$') { return $null }
    return [int]$Matches[1]
}

function Test-AddressInRanges {
    param([uint32]$Address, $Ranges)
    foreach ($range in @($Ranges)) {
        if (-not $range) { continue }
        if ($Address -ge $range.Start -and $Address -le $range.End) { return $true }
    }
    return $false
}

function ConvertTo-PoolRanges {
    param([string[]]$RangeText)
    $ranges = @()
    foreach ($text in @($RangeText)) {
        if (-not $text) { continue }
        foreach ($part in ($text -split ',')) {
            $piece = $part.Trim()
            if (-not $piece) { continue }
            if ($piece -match '^(\d{1,3}(?:\.\d{1,3}){3})-(\d{1,3}(?:\.\d{1,3}){3})$') {
                $ranges += [pscustomobject]@{
                    Start = (ConvertTo-UInt32Address $Matches[1])
                    End   = (ConvertTo-UInt32Address $Matches[2])
                    Text  = $piece
                }
            }
        }
    }
    return @($ranges)
}

function Select-VpnAddress {
    param(
        [string]$ExistingRemote,
        [string[]]$Taken,
        [string[]]$PoolRanges,
        [string]$PoolName
    )
    $existingOctet = ConvertTo-VpnOctet $ExistingRemote
    if ($null -ne $existingOctet) {
        return [pscustomobject]@{
            Address = ("172.16.91.{0}" -f $existingOctet)
            Reused  = $true
            Stopped = $false
            Pool    = ''
        }
    }
    $ranges = @(ConvertTo-PoolRanges $PoolRanges)
    $takenOctets = @{}
    foreach ($item in @($Taken)) {
        $octet = ConvertTo-VpnOctet $item
        if ($null -ne $octet) { $takenOctets[$octet] = $true }
    }
    foreach ($octet in $script:ReservedVpnOctets) { $takenOctets[$octet] = $true }
    $poolText = (@($ranges | ForEach-Object { $_.Text })) -join ', '
    if ($PoolName -and $ranges.Count -eq 0) {
        return [pscustomobject]@{
            Address = $null
            Reused  = $false
            Stopped = $true
            Pool    = "pool $PoolName was not readable"
        }
    }
    for ($octet = 3; $octet -le 28; $octet++) {
        if ($takenOctets.ContainsKey($octet)) { continue }
        $candidate = ConvertTo-UInt32Address ("172.16.91.{0}" -f $octet)
        if (Test-AddressInRanges -Address $candidate -Ranges $ranges) { continue }
        return [pscustomobject]@{
            Address = ("172.16.91.{0}" -f $octet)
            Reused  = $false
            Stopped = $false
            Pool    = $poolText
        }
    }
    if (-not $poolText) { $poolText = '(no remote pool)' }
    return [pscustomobject]@{
        Address = $null
        Reused  = $false
        Stopped = $true
        Pool    = $poolText
    }
}

function New-L2tpPassword {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $text = [Convert]::ToBase64String($bytes)
    return ($text -replace '[^a-zA-Z0-9]', 'x').Substring(0, 24)
}

function Resolve-L2tpPassword {
    param([string]$Existing)
    if (-not [string]::IsNullOrWhiteSpace($Existing)) { return $Existing }
    return (New-L2tpPassword)
}

function Test-IpsecSecret {
    param([string]$ServerSecret, [string]$ConfigSecret)
    if ([string]::IsNullOrEmpty($ServerSecret) -or [string]::IsNullOrEmpty($ConfigSecret)) {
        return 'mismatch'
    }
    if ($ServerSecret -ceq $ConfigSecret) { return 'match' }
    return 'mismatch'
}

function Test-RouterOsVersion {
    param([Parameter(Mandatory = $true)][string]$VersionText)
    $match = [regex]::Match($VersionText, '(\d+)\.(\d+)(?:\.(\d+))?')
    if (-not $match.Success) {
        return [pscustomobject]@{ Ok = $false; Message = (Get-UpgradeMessage -Running $VersionText) }
    }
    $parts = @(
        [int]$match.Groups[1].Value,
        [int]$match.Groups[2].Value,
        $(if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 0 })
    )
    for ($i = 0; $i -lt 3; $i++) {
        if ($parts[$i] -gt $script:VersionFloor[$i]) {
            return [pscustomobject]@{ Ok = $true; Message = '' }
        }
        if ($parts[$i] -lt $script:VersionFloor[$i]) {
            return [pscustomobject]@{ Ok = $false; Message = (Get-UpgradeMessage -Running $VersionText) }
        }
    }
    return [pscustomobject]@{ Ok = $true; Message = '' }
}

function Get-UpgradeMessage {
    param([string]$Running)
    $floor = ($script:VersionFloor -join '.')
    return @"
This board is running RouterOS $Running. The flash needs RouterOS $floor or newer because the generated file uses /user ssh-keys add and the RouterOS 7 wireless syntax. The floor is provisional until a bench run confirms those commands.
Do not expect this script to upgrade the board. Download the routeros package for its architecture (hAP ac lite is routeros-smips) from mikrotik.com, copy it to Files in Winbox, reboot, then run the flash again. Most boxed hAP ac lite boards ship on RouterOS 6, so the first attempt often stops here.
"@.Trim()
}

function Test-OnLinkFactoryBoard {
    param(
        [object[]]$LocalAddresses,
        [object[]]$ArpEntries
    )
    foreach ($local in @($LocalAddresses)) {
        if (-not $local) { continue }
        $cidr = ConvertTo-NetworkCidr ("{0}/{1}" -f $local.Ip, $local.Prefix)
        if ($cidr -ne '192.168.88.0/24') { continue }
        foreach ($arp in @($ArpEntries)) {
            if (-not $arp) { continue }
            if ($arp.Ip -ne '192.168.88.1') { continue }
            if ($arp.InterfaceAlias -ne $local.InterfaceAlias) { continue }
            $state = [string]$arp.State
            if ($state -eq 'Reachable' -or $state -eq 'Stale' -or $state -eq 'Permanent') {
                return [pscustomobject]@{ Found = $true; InterfaceAlias = $local.InterfaceAlias }
            }
        }
    }
    return [pscustomobject]@{ Found = $false; InterfaceAlias = '' }
}

function Get-ApplyStage {
    param(
        [switch]$Apply,
        [switch]$Confirmed,
        [switch]$ConfirmedBoard,
        [switch]$OnLink
    )
    if (-not $Apply) { return 'dry-run' }
    if (-not $Confirmed) { return 'need-kuca-confirm' }
    if (-not $ConfirmedBoard) { return 'kuca-written-need-board' }
    if (-not $OnLink) { return 'need-on-link' }
    return 'reset'
}

function ConvertTo-RosQuoted {
    param([AllowEmptyString()][string]$Value)
    if ($null -eq $Value) { $Value = '' }
    $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace('$', '\$')
    return '"' + $escaped + '"'
}

function Resolve-RoamingConfig {
    param(
        [Parameter(Mandatory = $true)]$Raw,
        [switch]$RequireSecrets
    )
    if (-not $Raw.name) { throw 'Config name is required.' }
    $name = [string]$Raw.name
    if ($name -notmatch '^[A-Za-z0-9][A-Za-z0-9-]{0,30}$') {
        throw "Name '$name' must start with a letter or digit and use only letters, digits, and hyphens."
    }
    $slug = ConvertTo-RoamingSlug $name
    $prefix = 24
    if ($Raw.prefixLength) { $prefix = [int]$Raw.prefixLength }
    $localPrefix = 24
    if ($Raw.localPrefixLength) { $localPrefix = [int]$Raw.localPrefixLength }
    $localNetwork = '172.31.250.0'
    if ($Raw.localNetwork) { $localNetwork = [string]$Raw.localNetwork }
    $homeNets = @('192.168.89.0/24', '10.0.10.0/24', '172.16.90.0/24')
    if ($Raw.homeNetworks) { $homeNets = @($Raw.homeNetworks) }
    $extra = @('192.168.90.0/24')
    if ($Raw.managementExtra) { $extra = @($Raw.managementExtra) }
    $l2tp = $Raw.l2tp
    $server = 'nyc.mostardesigns.com'
    $username = ''
    $password = ''
    $ipsec = ''
    if ($l2tp) {
        if ($l2tp.server) { $server = [string]$l2tp.server }
        if ($l2tp.username) { $username = [string]$l2tp.username }
        if ($l2tp.password) { $password = [string]$l2tp.password }
        if ($l2tp.ipsecSecret) { $ipsec = [string]$l2tp.ipsecSecret }
    }
    if (-not $username) { $username = "l2tp-roaming-$slug" }
    $wifi = [string]$Raw.wifiPassword
    $localWifi = [string]$Raw.localWifiPassword
    if (-not $localWifi) { $localWifi = $wifi }
    $country = 'united states'
    if ($Raw.country) { $country = [string]$Raw.country }
    $lan = Get-LanPlan -Network ([string]$Raw.lanNetwork) -PrefixLength $prefix
    $local = Get-LanPlan -Network $localNetwork -PrefixLength $localPrefix
    if ($RequireSecrets) {
        if (-not $wifi) { throw 'wifiPassword is required in the secrets file.' }
        if (-not $Raw.adminPassword) { throw 'adminPassword is required in the secrets file.' }
        if (-not $ipsec) { throw 'l2tp.ipsecSecret is required in the secrets file.' }
    }
    return [pscustomobject]@{
        Name            = $name
        Slug            = $slug
        Identity        = "$name-Roaming"
        NycSsid         = "$name-Roaming-NYC"
        LocalSsid       = "$name-Roaming"
        RadioSsid       = "$slug-radio"
        WifiPassword    = $wifi
        LocalWifiPassword = $localWifi
        AdminPassword   = [string]$Raw.adminPassword
        FactoryPassword = [string]$Raw.factoryPassword
        Lan             = $lan
        Local           = $local
        HomeNetworks    = $homeNets
        ManagementExtra = $extra
        L2tpServer      = $server
        L2tpUsername    = $username
        L2tpPassword    = $password
        IpsecSecret     = $ipsec
        Country         = $country
    }
}

function Format-RoamingPlan {
    param($Config, [string]$VpnAddress, [string]$IpsecResult, [int]$KeyCount, [string]$PoolNote)
    $lines = @(
        "identity: $($Config.Identity)",
        "vpn-lan: $($Config.Lan.Cidr)",
        "local-lan: $($Config.Local.Cidr)",
        "ppp-secret: $($Config.L2tpUsername)",
        "vpn-address: $VpnAddress",
        "ipsec: $IpsecResult",
        "admin-keys: $KeyCount",
        "pool: $PoolNote"
    )
    return ($lines -join [Environment]::NewLine)
}

function New-KucaJournal {
    param(
        [Parameter(Mandatory = $true)][string]$Slug,
        [Parameter(Mandatory = $true)][string]$Username,
        [Parameter(Mandatory = $true)][string]$LanCidr,
        [Parameter(Mandatory = $true)][string]$VpnAddress,
        [hashtable]$PreviousServices
    )
    $comment = "roaming:$Slug"
    $entries = New-Object System.Collections.Generic.List[object]
    $entries.Add([pscustomobject]@{ op = 'add'; kind = 'ppp-secret'; name = $Username })
    $entries.Add([pscustomobject]@{ op = 'add'; kind = 'route'; comment = $comment })
    $entries.Add([pscustomobject]@{ op = 'add'; kind = 'address-list'; list = 'support'; address = $LanCidr; comment = $comment })
    $entries.Add([pscustomobject]@{ op = 'add'; kind = 'address-list'; list = 'Local'; address = $LanCidr; comment = $comment })
    foreach ($service in @('www', 'api', 'api-ssl')) {
        $previous = ''
        if ($PreviousServices -and $PreviousServices.ContainsKey($service)) {
            $previous = [string]$PreviousServices[$service]
        }
        $entries.Add([pscustomobject]@{ op = 'set'; kind = 'service'; service = $service; previous = $previous })
    }
    return [pscustomobject]@{
        slug       = $Slug
        username   = $Username
        lanCidr    = $LanCidr
        vpnAddress = $VpnAddress
        entries    = $entries.ToArray()
    }
}

function Get-AppendedServiceAddress {
    param([string]$Previous, [Parameter(Mandatory = $true)][string]$Cidr)
    $parts = @()
    if ($Previous) {
        $parts = @($Previous.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    if ($parts -contains $Cidr) { return ($parts -join ',') }
    if ($parts.Count -eq 0) {
        throw "Refusing to replace an empty service address with only $Cidr."
    }
    $combined = New-Object System.Collections.Generic.List[string]
    foreach ($part in $parts) { $combined.Add([string]$part) }
    $combined.Add($Cidr)
    return ($combined -join ',')
}

function Get-KucaApplyCommands {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$VpnAddress,
        [switch]$WritePassword,
        [switch]$SecretExists,
        [hashtable]$PreviousServices
    )
    $comment = "roaming:$($Config.Slug)"
    $quotedComment = ConvertTo-RosQuoted "$comment $($Config.Identity) $($Config.Lan.Cidr)"
    $commands = New-Object System.Collections.Generic.List[string]
    if ($SecretExists) {
        $commands.Add(("/ppp secret set [find where name={0}] remote-address={1} comment={2}" -f (ConvertTo-RosQuoted $Config.L2tpUsername), $VpnAddress, $quotedComment))
    }
    else {
        $passArg = ''
        if ($WritePassword) { $passArg = " password=$(ConvertTo-RosQuoted $Config.L2tpPassword)" }
        $commands.Add(("/ppp secret add name={0} profile={1} service=l2tp remote-address={2}{3} comment={4}" -f (ConvertTo-RosQuoted $Config.L2tpUsername), (ConvertTo-RosQuoted 'mostardesigns.com l2tp'), $VpnAddress, $passArg, $quotedComment))
    }
    $commands.Add(("/ip route add dst-address={0} gateway={1} comment={2}" -f $Config.Lan.Cidr, $VpnAddress, (ConvertTo-RosQuoted $comment)))
    $commands.Add(("/ip firewall address-list add list=support address={0} comment={1}" -f $Config.Lan.Cidr, (ConvertTo-RosQuoted $comment)))
    $commands.Add(("/ip firewall address-list add list=Local address={0} comment={1}" -f $Config.Lan.Cidr, (ConvertTo-RosQuoted $comment)))
    foreach ($service in @('www', 'api', 'api-ssl')) {
        $previous = ''
        if ($PreviousServices -and $PreviousServices.ContainsKey($service)) {
            $previous = [string]$PreviousServices[$service]
        }
        $appended = Get-AppendedServiceAddress -Previous $previous -Cidr $Config.Lan.Cidr
        $commands.Add(("/ip service set {0} address={1}" -f $service, (ConvertTo-RosQuoted $appended)))
    }
    return $commands.ToArray()
}

function Get-KucaRollbackCommands {
    param($Journal)
    $commands = New-Object System.Collections.Generic.List[string]
    $entries = @($Journal.entries)
    for ($i = $entries.Count - 1; $i -ge 0; $i--) {
        $entry = $entries[$i]
        switch ($entry.kind) {
            'service' {
                $commands.Add(("/ip service set {0} address={1}" -f $entry.service, (ConvertTo-RosQuoted $entry.previous)))
            }
            'address-list' {
                $commands.Add(("/ip firewall address-list remove [find where list={0} and address={1} and comment={2}]" -f (ConvertTo-RosQuoted $entry.list), $entry.address, (ConvertTo-RosQuoted $entry.comment)))
            }
            'route' {
                if ($entry.op -eq 'set') {
                    $commands.Add(("/ip route set [find where comment={0}] gateway={1}" -f (ConvertTo-RosQuoted $entry.comment), $entry.previous))
                }
                else {
                    $commands.Add(("/ip route remove [find where comment={0}]" -f (ConvertTo-RosQuoted $entry.comment)))
                }
            }
            'ppp-secret' {
                if ($entry.op -eq 'set') {
                    $commands.Add(("/ppp secret set [find where name={0}] remote-address={1}" -f (ConvertTo-RosQuoted $entry.name), $entry.previous))
                }
                else {
                    $commands.Add(("/ppp secret remove [find where name={0}]" -f (ConvertTo-RosQuoted $entry.name)))
                }
            }
        }
    }
    return $commands.ToArray()
}

function Get-ServiceAddressList {
    param($Config)
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($cidr in @($Config.HomeNetworks)) { if ($cidr -and -not $items.Contains([string]$cidr)) { $items.Add([string]$cidr) } }
    foreach ($cidr in @($Config.ManagementExtra)) { if ($cidr -and -not $items.Contains([string]$cidr)) { $items.Add([string]$cidr) } }
    foreach ($cidr in @($Config.Lan.Cidr, $Config.Local.Cidr, '172.16.91.0/27')) {
        if ($cidr -and -not $items.Contains([string]$cidr)) { $items.Add([string]$cidr) }
    }
    return ($items -join ',')
}

function Get-JoinGuestSource {
    param([Parameter(Mandatory = $true)][ValidateSet('wireless', 'wifi')][string]$Package)
    if ($Package -eq 'wireless') {
        return @'
:global JoinSsid
:global JoinPass
:if ([:typeof $JoinSsid] = "nothing") do={ :error "set JoinSsid before running join-guest" }
:if ([:len $JoinSsid] = 0) do={ :error "JoinSsid is empty" }
:if ([:typeof $JoinPass] = "nothing") do={ :set JoinPass "" }
:local profile "uplink-sp"
:if ([:len $JoinPass] = 0) do={
  :set profile "guest-open"
} else={
  /interface wireless security-profiles set [find name="uplink-sp"] wpa2-pre-shared-key=$JoinPass
  :set profile "uplink-sp"
}
/interface wireless connect-list remove [find where comment="current-guest"]
/interface wireless connect-list add interface=wlan_uplink ssid=$JoinSsid security-profile=$profile comment="current-guest"
/interface wireless set [find name="wlan_uplink"] ssid=$JoinSsid security-profile=$profile disabled=no
/system script run roaming-wifi-channel
'@
    }
    return @'
:global JoinSsid
:global JoinPass
:if ([:typeof $JoinSsid] = "nothing") do={ :error "set JoinSsid before running join-guest" }
:if ([:len $JoinSsid] = 0) do={ :error "JoinSsid is empty" }
:if ([:typeof $JoinPass] = "nothing") do={ :set JoinPass "" }
:if ([:len $JoinPass] = 0) do={
  /interface wifi configuration set cfg-station security=sec-open
} else={
  /interface wifi security set sec-uplink passphrase=$JoinPass
  /interface wifi configuration set cfg-station security=sec-uplink
}
/interface wifi configuration set cfg-station ssid=$JoinSsid
/system script run roaming-wifi-mode
'@
}

function Get-ChannelScriptSource {
    return @'
:local uplink [/interface wireless find where name="wlan_uplink"]
:if ([:len $uplink] = 0) do={ :return }
:if ([/interface wireless get $uplink running]) do={ :return }
:local ssid [/interface wireless get $uplink ssid]
:if ([:len $ssid] = 0) do={ :return }
:local freq ""
:do {
  :foreach row in=[/interface wireless scan wlan_roaming duration=5] do={
    :if (($row->"ssid") = $ssid) do={
      :if ([:len $freq] = 0) do={
        :local raw ($row->"channel")
        :local slash [:find $raw "/"]
        :if ($slash >= 0) do={ :set freq [:pick $raw 0 $slash] } else={ :set freq $raw }
      }
    }
  }
} on-error={ :log warning "roaming-wifi-channel: scan failed" }
:if ([:len $freq] > 0) do={
  /interface wireless set [find name="wlan_roaming"] scan-list=$freq frequency=auto
  :log info ("roaming-wifi-channel: scan-list=" . $freq)
}
'@
}

function Get-WifiModeScriptSource {
    return @'
:local etherUp false
:local client [/ip dhcp-client find where interface="ether1 - wan"]
:if ([:len $client] > 0) do={
  :if ([/ip dhcp-client get $client status] = "bound") do={
    :if ([/interface get [find name="ether1 - wan"] running]) do={ :set etherUp true }
  }
}
:local ssid ""
:do { :set ssid [/interface wifi configuration get cfg-station ssid] } on-error={}
:if ($etherUp || [:len $ssid] = 0) do={
  /interface wifi set [find name="wlan_uplink"] configuration=cfg-ap-hidden
  :log info "roaming-wifi-mode: AP master"
} else={
  /interface wifi set [find name="wlan_uplink"] configuration=cfg-station
  :log info "roaming-wifi-mode: station master"
}
'@
}

function Get-IspScriptSource {
    param([string[]]$HomeNetworks)
    $adds = New-Object System.Collections.Generic.List[string]
    foreach ($cidr in @($HomeNetworks)) {
        $adds.Add(('  :if ($ip in {0}) do={{ :set atHome true }}' -f $cidr))
    }
    $body = @'
:local wan ""
:local addr ""
:local ether [/ip dhcp-client find where interface="ether1 - wan"]
:if ([:len $ether] > 0) do={
  :if ([/ip dhcp-client get $ether status] = "bound") do={
    :if ([/interface get [find name="ether1 - wan"] running]) do={
      :set wan "ether1 - wan"
      :set addr [/ip dhcp-client get $ether address]
    }
  }
}
:if ([:len $wan] = 0) do={
  :local wifi [/ip dhcp-client find where interface="wlan_uplink"]
  :if ([:len $wifi] > 0) do={
    :if ([/ip dhcp-client get $wifi status] = "bound") do={
      :if ([/interface get [find name="wlan_uplink"] running]) do={
        :set wan "wlan_uplink"
        :set addr [/ip dhcp-client get $wifi address]
      }
    }
  }
}
:local atHome false
:if ([:len $addr] > 0) do={
  :local ip [:toip [:pick $addr 0 [:find $addr "/"]]]
__HOME_TESTS__
}
:if ($atHome) do={
  /interface l2tp-client set [find name="mikrotik-kuca-l2tp"] disabled=yes
  /ip firewall mangle set [find where comment="roaming-via-nyc"] disabled=yes
  /ip firewall nat set [find where comment="roaming-home-masquerade"] out-interface=$wan disabled=no
} else={
  :if ([:len $wan] > 0) do={
    /interface l2tp-client set [find name="mikrotik-kuca-l2tp"] disabled=no
    /ip firewall mangle set [find where comment="roaming-via-nyc"] disabled=no
    /ip firewall nat set [find where comment="roaming-home-masquerade"] disabled=yes
  }
}
:local localOut "ether1 - wan"
:if ([:len [/interface find where name="wlan_uplink"]] > 0) do={
  :if ([/interface get [find name="wlan_uplink"] running]) do={ :set localOut "wlan_uplink" }
}
/ip firewall nat set [find where comment="roaming-local-masquerade"] out-interface=$localOut disabled=no
:local dnsClient [/ip dhcp-client find where interface=$localOut]
:if ([:len $dnsClient] > 0) do={
  :local dns [/ip dhcp-client get $dnsClient dns-server]
  :if ([:len $dns] > 0) do={
    /ip dhcp-server network set [find where comment="roaming-local"] dns-server=$dns
  }
}
'@
    return $body.Replace('__HOME_TESTS__', ($adds -join "`n"))
}

function New-RoamingRsc {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][ValidateSet('wireless', 'wifi')][string]$Package,
        [string[]]$LanPorts = @('ether2', 'ether3', 'ether4', 'ether5'),
        [string[]]$SshKeys,
        [string]$SecondRadioName = 'wlan2'
    )
    if (@($SshKeys).Count -ne 2) { throw 'Exactly two admin SSH keys are required.' }
    if ($Package -eq 'wifi' -and $SecondRadioName -eq 'wlan2') { $SecondRadioName = 'wifi2' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('/interface bridge')
    $lines.Add('add name=nyc_bridge comment=roaming-vpn-lan protocol-mode=none')
    $lines.Add('add name="roaming lan bridge" comment=roaming-local-lan protocol-mode=none')
    $lines.Add('/interface ethernet')
    $lines.Add('set [find default-name=ether1] name="ether1 - wan" comment=roaming-wan')
    $lines.Add('/interface bridge port')
    foreach ($port in @($LanPorts)) {
        $lines.Add("add bridge=nyc_bridge interface=$port")
    }
    $lines.Add('/interface list')
    $lines.Add('add name=LAN')
    $lines.Add('add name=WAN')
    $lines.Add('/interface list member')
    $lines.Add('add interface=nyc_bridge list=LAN')
    $lines.Add('add interface="roaming lan bridge" list=LAN')
    $lines.Add('add interface="ether1 - wan" list=WAN')
    $lines.Add('/ip address')
    $lines.Add(("add address={0} interface=nyc_bridge network={1} comment=roaming-vpn-lan" -f $Config.Lan.Address, $Config.Lan.Network))
    $lines.Add(("add address={0} interface=`"roaming lan bridge`" network={1} comment=roaming-local-lan" -f $Config.Local.Address, $Config.Local.Network))
    $lines.Add('/user')
    $lines.Add(("set [find name=admin] password={0}" -f (ConvertTo-RosQuoted $Config.AdminPassword)))
    $lines.Add('/user ssh-keys')
    foreach ($key in @($SshKeys)) {
        $lines.Add(("add user=admin key={0}" -f (ConvertTo-RosQuoted $key.Trim())))
    }
    $lines.Add('/tool mac-server')
    $lines.Add('set allowed-interface-list=LAN')
    $lines.Add('/tool mac-server mac-winbox')
    $lines.Add('set allowed-interface-list=LAN')
    $lines.Add('/system identity')
    $lines.Add(("set name={0}" -f (ConvertTo-RosQuoted $Config.Identity)))

    $waitType = 'wireless'
    if ($Package -eq 'wifi') { $waitType = 'wifi' }
    $lines.Add(':delay 1s')
    $lines.Add(':local radioWait 0')
    $lines.Add(':local radiosReady false')
    $lines.Add(':while ($radioWait < 60) do={')
    $lines.Add('  :do {')
    $lines.Add(("    :if ([:len [/interface {0} find]] > 0) do={{ :set radiosReady true }}" -f $waitType))
    $lines.Add('  } on-error={}')
    $lines.Add('  :if ($radiosReady) do={ :set radioWait 60 } else={ :delay 2s; :set radioWait ($radioWait + 1) }')
    $lines.Add('}')
    $lines.Add(':if ($radiosReady = false) do={ :log error "roaming-flash: radio interfaces did not appear" }')

    $serviceAddress = Get-ServiceAddressList $Config
    $lines.Add('/ip pool')
    $lines.Add(("add name=roaming-vpn-pool ranges={0}" -f $Config.Lan.Pool))
    $lines.Add(("add name=roaming-local-pool ranges={0}" -f $Config.Local.Pool))
    $lines.Add('/ip dhcp-server')
    $lines.Add('add name=roaming-vpn interface=nyc_bridge address-pool=roaming-vpn-pool lease-time=1d')
    $lines.Add('add name=roaming-local interface="roaming lan bridge" address-pool=roaming-local-pool lease-time=10m')
    $lines.Add('/ip dhcp-server network')
    $lines.Add(("add address={0} gateway={1} dns-server={1} comment=roaming-vpn" -f $Config.Lan.Cidr, $Config.Lan.Gateway))
    $lines.Add(("add address={0} gateway={1} dns-server=8.8.8.8 comment=roaming-local" -f $Config.Local.Cidr, $Config.Local.Gateway))
    $lines.Add('/ip dns')
    $lines.Add('set allow-remote-requests=yes servers=10.0.10.10,8.8.8.8')
    $lines.Add('/ip firewall address-list')
    foreach ($cidr in @($Config.HomeNetworks)) {
        $lines.Add(("add list=roaming-home-lan address={0} comment=roaming-home" -f $cidr))
    }
    foreach ($cidr in ($serviceAddress -split ',')) {
        $lines.Add(("add list=roaming-mgmt address={0} comment=roaming-mgmt" -f $cidr))
    }
    $lines.Add('/routing table')
    $lines.Add('add name=via_nyc fib')
    $lines.Add('/ip route')
    $lines.Add('add dst-address=0.0.0.0/0 gateway=172.16.91.1 routing-table=via_nyc comment=roaming-via-nyc')
    $lines.Add('/interface l2tp-client')
    $lines.Add(("add name=mikrotik-kuca-l2tp connect-to={0} user={1} password={2} ipsec-secret={3} use-ipsec=yes add-default-route=yes default-route-distance=1 use-peer-dns=no disabled=yes profile=default-encryption comment=roaming-l2tp" -f (ConvertTo-RosQuoted $Config.L2tpServer), (ConvertTo-RosQuoted $Config.L2tpUsername), (ConvertTo-RosQuoted $Config.L2tpPassword), (ConvertTo-RosQuoted $Config.IpsecSecret)))
    $lines.Add('/ip firewall mangle')
    $lines.Add('add chain=prerouting action=mark-routing new-routing-mark=via_nyc passthrough=no in-interface=nyc_bridge comment=roaming-via-nyc disabled=yes')
    $lines.Add('/ip firewall nat')
    $lines.Add(("add chain=srcnat action=masquerade src-address={0} out-interface=`"ether1 - wan`" comment=roaming-home-masquerade" -f $Config.Lan.Cidr))
    $lines.Add(("add chain=srcnat action=masquerade src-address={0} out-interface=`"ether1 - wan`" comment=roaming-local-masquerade" -f $Config.Local.Cidr))
    $lines.Add('/ip firewall filter')
    $lines.Add('add chain=input action=accept connection-state=established,related,untracked comment=roaming-established')
    $lines.Add('add chain=input action=accept protocol=icmp comment=roaming-icmp')
    $lines.Add('add chain=input action=accept src-address-list=roaming-mgmt dst-port=22,80,8291,8728,8729 protocol=tcp comment=roaming-mgmt')
    $lines.Add('add chain=input action=accept in-interface=all-ppp comment=roaming-from-vpn')
    $lines.Add('add chain=input action=accept in-interface=nyc_bridge comment=roaming-from-vpn-lan')
    $lines.Add('add chain=input action=accept in-interface="roaming lan bridge" comment=roaming-from-local-lan')
    $lines.Add('add chain=input action=drop in-interface-list=WAN comment=roaming-drop-wan')
    $lines.Add('/ip service')
    $quotedServices = ConvertTo-RosQuoted $serviceAddress
    $lines.Add("set ssh address=$quotedServices")
    $lines.Add("set www address=$quotedServices")
    $lines.Add("set winbox address=$quotedServices")
    $lines.Add("set api address=$quotedServices")
    $lines.Add("set api-ssl address=$quotedServices")
    $lines.Add('set ftp disabled=yes')
    $lines.Add('set telnet disabled=yes')

    if ($Package -eq 'wireless') {
        $lines.Add('/interface wireless security-profiles')
        $lines.Add('set [find default=yes] supplicant-identity=MikroTik')
        $lines.Add(("add name=ap-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key={0}" -f (ConvertTo-RosQuoted $Config.WifiPassword)))
        $lines.Add(("add name=local-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key={0}" -f (ConvertTo-RosQuoted $Config.LocalWifiPassword)))
        $lines.Add('add name=uplink-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=""')
        $lines.Add('add name=guest-open mode=none')
        $lines.Add('/interface wireless')
        $lines.Add(("set [find default-name=wlan1] name=wlan_roaming mode=ap-bridge ssid={0} security-profile=ap-sp country={1} frequency=auto channel-width=20mhz band=2ghz-b/g/n hide-ssid=yes disabled=no" -f (ConvertTo-RosQuoted $Config.RadioSsid), (ConvertTo-RosQuoted $Config.Country)))
        $lines.Add(("add master-interface=wlan_roaming name=wlan_nyc ssid={0} security-profile=ap-sp disabled=no" -f (ConvertTo-RosQuoted $Config.NycSsid)))
        $lines.Add(("add master-interface=wlan_roaming name=wlan_kuca ssid={0} security-profile=local-sp disabled=no" -f (ConvertTo-RosQuoted $Config.LocalSsid)))
        $lines.Add('add master-interface=wlan_roaming name=wlan_uplink mode=station ssid="" security-profile=uplink-sp disabled=no')
        if ($SecondRadioName) {
            $lines.Add(("set [find default-name={0}] name=wlan_nyc_5 mode=ap-bridge ssid={1} security-profile=ap-sp country={2} frequency=auto disabled=no" -f $SecondRadioName, (ConvertTo-RosQuoted $Config.NycSsid), (ConvertTo-RosQuoted $Config.Country)))
            $lines.Add(("add master-interface=wlan_nyc_5 name=wlan_kuca_5 ssid={0} security-profile=local-sp disabled=no" -f (ConvertTo-RosQuoted $Config.LocalSsid)))
        }
        $lines.Add('/interface bridge port')
        $lines.Add('add bridge=nyc_bridge interface=wlan_nyc')
        $lines.Add('add bridge="roaming lan bridge" interface=wlan_kuca')
        if ($SecondRadioName) {
            $lines.Add('add bridge=nyc_bridge interface=wlan_nyc_5')
            $lines.Add('add bridge="roaming lan bridge" interface=wlan_kuca_5')
        }
    }
    else {
        $lines.Add('/interface wifi security')
        $lines.Add(("add name=sec-ap authentication-types=wpa2-psk passphrase={0}" -f (ConvertTo-RosQuoted $Config.WifiPassword)))
        $lines.Add(("add name=sec-local authentication-types=wpa2-psk passphrase={0}" -f (ConvertTo-RosQuoted $Config.LocalWifiPassword)))
        $lines.Add('add name=sec-uplink authentication-types=wpa2-psk passphrase=""')
        $lines.Add('add name=sec-open')
        $lines.Add('/interface wifi configuration')
        $lines.Add(("add name=cfg-ap-hidden mode=ap ssid={0} country={1} hide-ssid=yes security=sec-ap" -f (ConvertTo-RosQuoted $Config.RadioSsid), (ConvertTo-RosQuoted $Config.Country)))
        $lines.Add(("add name=cfg-nyc mode=ap ssid={0} country={1} security=sec-ap" -f (ConvertTo-RosQuoted $Config.NycSsid), (ConvertTo-RosQuoted $Config.Country)))
        $lines.Add(("add name=cfg-local mode=ap ssid={0} country={1} security=sec-local" -f (ConvertTo-RosQuoted $Config.LocalSsid), (ConvertTo-RosQuoted $Config.Country)))
        $lines.Add(("add name=cfg-station mode=station ssid=`"`" country={0} security=sec-uplink" -f (ConvertTo-RosQuoted $Config.Country)))
        $lines.Add('/interface wifi')
        $lines.Add('set [find default-name=wifi1] name=wlan_uplink configuration=cfg-ap-hidden disabled=no')
        $lines.Add('add name=wifi-nyc master-interface=wlan_uplink configuration=cfg-nyc disabled=no')
        $lines.Add('add name=wifi-local master-interface=wlan_uplink configuration=cfg-local disabled=no')
        if ($SecondRadioName) {
            $lines.Add(("set [find default-name={0}] name=wifi-5 configuration=cfg-nyc disabled=no" -f $SecondRadioName))
            $lines.Add('add name=wifi-local-5 master-interface=wifi-5 configuration=cfg-local disabled=no')
        }
        $lines.Add('/interface bridge port')
        $lines.Add('add bridge=nyc_bridge interface=wifi-nyc')
        $lines.Add('add bridge="roaming lan bridge" interface=wifi-local')
        if ($SecondRadioName) {
            $lines.Add('add bridge=nyc_bridge interface=wifi-5')
            $lines.Add('add bridge="roaming lan bridge" interface=wifi-local-5')
        }
    }

    $isp = Get-IspScriptSource -HomeNetworks $Config.HomeNetworks
    $lines.Add('/system script')
    $lines.Add('add name=roaming-isp-routes policy=read,write,test,policy dont-require-permissions=no source={')
    foreach ($row in ($isp -split "`n")) { $lines.Add($row.TrimEnd("`r")) }
    $lines.Add('}')
    $lines.Add('add name=join-guest policy=read,write,test,policy dont-require-permissions=no source={')
    foreach ($row in (Get-JoinGuestSource -Package $Package) -split "`n") { $lines.Add($row.TrimEnd("`r")) }
    $lines.Add('}')
    if ($Package -eq 'wireless') {
        $lines.Add('add name=roaming-wifi-channel policy=read,write,test,policy,sniff dont-require-permissions=no source={')
        foreach ($row in (Get-ChannelScriptSource) -split "`n") { $lines.Add($row.TrimEnd("`r")) }
        $lines.Add('}')
    }
    else {
        $lines.Add('add name=roaming-wifi-mode policy=read,write,test,policy dont-require-permissions=no source={')
        foreach ($row in (Get-WifiModeScriptSource) -split "`n") { $lines.Add($row.TrimEnd("`r")) }
        $lines.Add('}')
    }
    $lines.Add('/system scheduler')
    $lines.Add('add name=roaming-isp-routes interval=1m on-event=roaming-isp-routes policy=read,write,test,policy start-time=startup')
    if ($Package -eq 'wireless') {
        $lines.Add('add name=roaming-wifi-channel interval=1m on-event=roaming-wifi-channel policy=read,write,test,policy,sniff start-time=startup')
    }
    else {
        $lines.Add('add name=roaming-wifi-mode interval=1m on-event=roaming-wifi-mode policy=read,write,test,policy start-time=startup')
    }
    $lines.Add('/ip dhcp-client')
    $lines.Add('add interface="ether1 - wan" add-default-route=yes default-route-distance=2 check-gateway=ping use-peer-dns=no use-peer-ntp=no script=roaming-isp-routes comment=roaming-wan')
    $lines.Add('add interface=wlan_uplink add-default-route=yes default-route-distance=3 check-gateway=ping use-peer-dns=no use-peer-ntp=no script=roaming-isp-routes comment=roaming-wifi-wan')
    $lines.Add('/system script')
    $lines.Add('add name=roaming-delete-flash policy=read,write,policy dont-require-permissions=no source={')
    $lines.Add('  :do { /file remove [find where name="flash.rsc"] } on-error={}')
    $lines.Add('}')
    $lines.Add('/system scheduler')
    $lines.Add('add name=roaming-delete-flash on-event=roaming-delete-flash policy=read,write,policy start-time=startup')
    return ($lines -join "`n")
}

function Build-KucaChangeSet {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$VpnAddress,
        [Parameter(Mandatory = $true)]$Snapshot,
        [switch]$WritePassword
    )
    $comment = "roaming:$($Config.Slug)"
    $entries = New-Object System.Collections.Generic.List[object]
    $commands = New-Object System.Collections.Generic.List[string]
    $secretRows = @()
    if ($Snapshot.Secrets) { $secretRows = @($Snapshot.Secrets) }
    $existing = $secretRows | Where-Object { $_.Name -eq $Config.L2tpUsername } | Select-Object -First 1
    $quotedName = ConvertTo-RosQuoted $Config.L2tpUsername
    $quotedComment = ConvertTo-RosQuoted "$comment $($Config.Identity) $($Config.Lan.Cidr)"
    if ($existing) {
        $commands.Add("/ppp secret set [find where name=$quotedName] remote-address=$VpnAddress comment=$quotedComment")
        $entries.Add([pscustomobject]@{ op = 'set'; kind = 'ppp-secret'; name = $Config.L2tpUsername; previous = [string]$existing.Remote })
    }
    else {
        $passArg = ''
        if ($WritePassword) { $passArg = " password=$(ConvertTo-RosQuoted $Config.L2tpPassword)" }
        $commands.Add("/ppp secret add name=$quotedName profile=$(ConvertTo-RosQuoted 'mostardesigns.com l2tp') service=l2tp remote-address=$VpnAddress$passArg comment=$quotedComment")
        $entries.Add([pscustomobject]@{ op = 'add'; kind = 'ppp-secret'; name = $Config.L2tpUsername })
    }
    $routeRows = @()
    if ($Snapshot.Routes) { $routeRows = @($Snapshot.Routes) }
    $route = $routeRows | Where-Object { $_.Comment -eq $comment } | Select-Object -First 1
    if ($route) {
        $commands.Add("/ip route set [find where comment=$(ConvertTo-RosQuoted $comment)] gateway=$VpnAddress")
        $entries.Add([pscustomobject]@{ op = 'set'; kind = 'route'; comment = $comment; previous = [string]$route.Gateway })
    }
    else {
        $commands.Add("/ip route add dst-address=$($Config.Lan.Cidr) gateway=$VpnAddress comment=$(ConvertTo-RosQuoted $comment)")
        $entries.Add([pscustomobject]@{ op = 'add'; kind = 'route'; comment = $comment })
    }
    foreach ($listName in @('support', 'Local')) {
        $listRows = @()
        if ($Snapshot.AddressLists) { $listRows = @($Snapshot.AddressLists) }
        $have = $listRows | Where-Object { $_.List -eq $listName -and $_.Address -eq $Config.Lan.Cidr } | Select-Object -First 1
        if (-not $have) {
            $commands.Add("/ip firewall address-list add list=$listName address=$($Config.Lan.Cidr) comment=$(ConvertTo-RosQuoted $comment)")
            $entries.Add([pscustomobject]@{ op = 'add'; kind = 'address-list'; list = $listName; address = $Config.Lan.Cidr; comment = $comment })
        }
    }
    foreach ($service in @('www', 'api', 'api-ssl')) {
        $previous = ''
        if ($Snapshot.Services -and $Snapshot.Services.ContainsKey($service)) {
            $previous = [string]$Snapshot.Services[$service]
        }
        $appended = Get-AppendedServiceAddress -Previous $previous -Cidr $Config.Lan.Cidr
        $commands.Add("/ip service set $service address=$(ConvertTo-RosQuoted $appended)")
        $entries.Add([pscustomobject]@{ op = 'set'; kind = 'service'; service = $service; previous = $previous })
    }
    return [pscustomobject]@{
        Commands = $commands.ToArray()
        Journal  = [pscustomobject]@{
            slug       = $Config.Slug
            username   = $Config.L2tpUsername
            lanCidr    = $Config.Lan.Cidr
            vpnAddress = $VpnAddress
            entries    = $entries.ToArray()
        }
    }
}

function ConvertFrom-RosTerse {
    param([string]$Text)
    $rows = @()
    foreach ($line in ($Text -split "`r?`n")) {
        if (-not $line.Trim()) { continue }
        $row = @{}
        foreach ($match in [regex]::Matches($line, '([A-Za-z][\w-]*)=("([^"]*)"|(\S+))')) {
            $value = $match.Groups[4].Value
            if ($match.Groups[2].Value.StartsWith('"')) { $value = $match.Groups[3].Value }
            $row[$match.Groups[1].Value] = $value
        }
        if ($row.Count -gt 0) { $rows += ,$row }
    }
    return @($rows)
}

function Read-KeyValueSecret {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Secret file not found: $Path" }
    $map = @{}
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
        $split = $line.IndexOf('=')
        if ($split -lt 1) { continue }
        $map[$line.Substring(0, $split).Trim()] = $line.Substring($split + 1).Trim()
    }
    return $map
}

function Get-WirelessPackageChoice {
    param([string]$WirelessPrint, [string]$WifiPrint)
    $hasWireless = $WirelessPrint -match 'wlan\d'
    $hasWifi = $WifiPrint -match 'wifi\d'
    if ($hasWireless -and -not $hasWifi) { return 'wireless' }
    if ($hasWifi -and -not $hasWireless) { return 'wifi' }
    if ($hasWireless -and $hasWifi) { return 'wireless' }
    return ''
}
