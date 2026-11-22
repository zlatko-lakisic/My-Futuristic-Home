# FreeIPA (`mostardesigns.com`)

## Role

- **VM:** Proxmox QEMU 106 (`freeipa`) on `vmbr0`
- **IP / DNS:** `10.0.10.10` · `freeipa.mostardesigns.com`
- **Domain:** `mostardesigns.com` (Kerberos realm `MOSTARDESIGNS.COM`)
- **Clients:** house DHCP DNS, Proxmox LDAP realm, Windows domain join, mail and other LDAP consumers

## Health notes (2026-11-22)

Core services (`ipa`, `dirsrv@MOSTARDESIGNS-COM`, `krb5kdc`, `kadmin`, `httpd`) were active; LDAP/LDAPS bind from Proxmox succeeded; realm sync dry-run OK. Windows `nltest /dsgetdc:mostardesigns.com` resolved the DC.

Open issues worth tracking (not blockers for Proxmox LDAP on port 389):

1. **`/var/lib/ipa/certs/httpd.crt` is a Let's Encrypt leaf** (issuer YR1, installed ~2026-11-06), not an IPA CA-signed cert. `ipa-healthcheck` then reports Dogtag/OpenSSL chain failures (`unable to get local issuer certificate`). Restore an IPA-managed httpd cert (or properly dual-stack LE + IPA trust) when touching FreeIPA TLS.
2. **`named-pkcs11.service` is masked**; DNS still answers via a running `named` process. Leave as-is unless DNS breaks.

## Proxmox login

See [proxmox.md](proxmox.md) Auth section. Userids synced into PVE are lowercase; mixed-case logins fail with `no such user`.
