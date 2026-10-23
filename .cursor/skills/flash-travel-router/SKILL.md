---
name: flash-travel-router
description: >-
  Interviews the user and flashes a spare MikroTik as a travel router like
  Kuca-Roaming. Use when the user wants to flash, provision, or set up a new
  travel router, hAP ac lite, RB952Ui-5ac2nD, guest Wi-Fi join-guest, or run
  scripts/flash_roaming_mikrotik.ps1 or scripts/flash_roaming_mikrotik.sh.
---

# Flash a travel router

Detect the operating system before the first command and keep that choice for the whole session. Do not ask the user which script to run.

- Windows (`win32`): `powershell -ExecutionPolicy Bypass -File scripts/flash_roaming_mikrotik.ps1`
- macOS or Linux: `bash scripts/flash_roaming_mikrotik.sh`

Flags for the PowerShell script are `-Config`, `-Apply`, `-Confirmed`, `-ConfirmedBoard`, `-Rollback`, and `-Offline`. Flags for the shell script are `--config`, `--apply`, `--confirmed`, `--confirmed-board`, `--rollback`, and `--offline`. Every command below names both. Run only the one that matches this system.

The shell script uses OpenSSH and `SSH_ASKPASS`. Do not install or use sshpass. Ask with the AskQuestion tool, one or two questions per turn. Every question has clickable choices. The form's Other field is the fill-in. If the value they need is not one of the choices, they type it in Other. A choice that says "type it in Other" is not answered until Other has text. Ask that question again when it does not.

Write answers only to `.cursor/secrets/roaming-flash.json`. Do not print passwords, the IPsec secret, or SSH keys. Do not commit that file. Do not edit the plan file.

Start from the repo root. Kuca login is `.cursor/secrets/.router-kuca`. Mostar login is `.cursor/secrets/.router-mostar`.

## Before questions

On Windows, install Posh-SSH when `Get-Module -ListAvailable -Name Posh-SSH` finds nothing:

```powershell
Install-Module Posh-SSH -Scope CurrentUser
```

On macOS and Linux, OpenSSH and `python3` must already be present. Do not install sshpass.

Copy `infrastructure/roaming/roaming.example.json` to `.cursor/secrets/roaming-flash.json` if that secrets file is missing. Then interview. Update the secrets file as answers arrive. Leave `l2tp.password` empty until they choose to type one.

Refuse name `Kuca`, LAN `192.168.86.0/24`, username `l2tp-roaming-kuca`, and VPN address `172.16.91.25` unless they explicitly say this is a re-flash of the live travel router. Even then, do not reset serial `628105BB1449`, Kuca, or Kuca-Mostar.

## Questions

Ask in this order. Recommended choice goes first.

1. **Name.** Prompt: "Router name. Identity becomes {Name}-Roaming. SSIDs become {Name}-Roaming-NYC and {Name}-Roaming."
   - Travel
   - Cabin
   - Other: any other name. `Kuca` is refused.

2. **VPN LAN.** Prompt: "Subnet for the VPN SSID and LAN ports. /24 unless you change the prefix next."
   - 10.50.0.0
   - 10.51.0.0
   - 192.168.87.0
   - Other: a different network address. `192.168.86.0` is refused.

3. **Prefix length.** Prompt: "How large is that VPN LAN? 24 is the normal pool."
   - 24
   - 23 (larger)
   - 25 (smaller)
   - Other: 16 through 29. The network address must be aligned.

4. **Wi-Fi password.** Prompt: "Password for both SSIDs. Type it in Other."
   - Type one password in Other (both SSIDs)
   - Type the VPN SSID password in Other, then ask for a second local SSID password
   - If they pick the second, ask again with "Type the local SSID password in Other" and two dummy choices they must not use without Other: "Same as the VPN SSID" and "Type a different password in Other".

5. **Admin password.** Prompt: "Password for admin after the flash."
   - Generate one and store it in the secrets file
   - Type it in Other

6. **Sticker password.** Prompt: "Factory admin password on the sticker."
   - Blank. This board has no sticker password
   - Type the sticker password in Other

7. **L2TP password.** Prompt: "Password for this router's new Kuca PPP secret."
   - Generate one and store it
   - Type it in Other

8. **IPsec secret.** Prompt: "Existing Kuca L2TP IPsec secret. It must match the server. It is not printed."
   - Type it in Other
   - I will paste it into the secrets file myself. Stop until that field is non-empty

9. **Local SSID LAN.** Prompt: "Subnet for {Name}-Roaming, the splash-page SSID. It is not registered on Kuca."
   - 172.31.250.0/24
   - 172.31.251.0/24
   - Other: a different aligned subnet. It must not overlap the VPN LAN

10. **Country.** Prompt: "Wi-Fi regulatory country."
    - united states
    - Other: a RouterOS country name

Do not ask the user to pick a VPN address. The dry-run chooses the lowest free host outside the shared pool.

## Dry-run

Keep this computer on the house network. The new router stays unplugged. Run the command for this operating system only.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/flash_roaming_mikrotik.ps1 -Config .cursor/secrets/roaming-flash.json
```

macOS or Linux:

```bash
bash scripts/flash_roaming_mikrotik.sh --config .cursor/secrets/roaming-flash.json
```

Show the script's printout. It has identity, both subnets, secret name, VPN address, `ipsec: match`, and `admin-keys: 2`. Then ask:

**Register on Kuca?**
- Yes. Register this secret, route, and firewall entries
- No. Change a setting (return to the question they name)
- Stop. Do not change Kuca

Only the first choice continues.

## Register, then cable

Run the same script chosen above. Windows adds `-Apply -Confirmed`. macOS or Linux adds `--apply --confirmed`.

Tell them Kuca is registered and the journal is under `infrastructure/roaming/out/`. Ask:

**Is a LAN port cabled to this PC?**
- Yes. ether2, ether3, ether4, or ether5 is connected. ether1 is empty
- Not yet
- Roll back the Kuca registration

Wait while the answer is "Not yet". On rollback:

Run the same script chosen above. Windows uses `-Rollback`. macOS or Linux uses `--rollback`.

This PC must be back on the house network for rollback.

## Reset

Run the same script chosen above. Windows uses `-Apply -Confirmed -ConfirmedBoard`. macOS or Linux uses `--apply --confirmed --confirmed-board`.

Run it only after they said the cable is connected. Before that command, if you already read the board, ask:

**Reset this board?** Include serial, model, RouterOS version, VPN address, and subnet in the prompt. Do not include passwords.
- Yes. Reset this board only
- No. Leave Kuca registered and stop
- Roll back the Kuca registration

A RouterOS version below 7.15 stops the reset and prints the upgrade step. Ask:

**The board needs RouterOS 7.15 or newer.**
- I upgraded it. Try the reset again
- Roll back Kuca
- Stop

`192.168.88.1` must be on-link on the adapter cabled to the board. A routed answer can be Mostar. Say so and ask them to move the cable onto ether2–ether5. Do not continue.

## After it boots

Tell them the identity, the VPN SSID, and the local SSID. Guest Wi-Fi is not part of the flash. When they want to join one, ask:

**Guest network.**
- Open network. Type only the SSID in Other
- WPA2. Type `SSID` and the password in Other as `ssid=... password=...`

Then SSH to the board and run `join-guest`. Do not print the password. The splash page is opened from `{Name}-Roaming`, not from `{Name}-Roaming-NYC`.
