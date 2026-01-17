# 🗄 Storage: NAS1 (Primary NVMe Array)

## **Overview**
NAS1 is the primary high-speed storage tier for the network, providing low-latency access to media, backups, and VM disks over the Perimeter network. It is built on the Rockchip RK3588 platform for superior I/O throughput.

## **Hardware Specifications**
- **Base Board:** [FriendlyElec CM3588 NAS Kit](https://www.friendlyelec.com/index.php?route=product/product&product_id=294)
- **CPU:** Rockchip RK3588 (Octa-core: 4x Cortex-A76 + 4x Cortex-A55)
- **RAM:** 16GB LPDDR4x
- **OS Storage:** 120GB Industrial eMMC (Selected for OS longevity)
- **Data Storage:** 4x 3.84TB TEAMGROUP MP34 NVMe SSDs (TM8FP4004T)
- **Networking:** Gigabit Ethernet (Connected to CSS326)
- **Enclosure:** [3D Printed 10" Rack Case](https://www.printables.com/model/826870-friendlyelec-cm3588-nas-case-for-10-rack) (Printed in PETG for thermal resistance).

## **Software & Filesystem**
- **Operating System:** OpenMediaVault (OMV) v6.9
- **Storage Configuration:** RAID 5
- **Total Raw Capacity:** 15.36 TB
- **Usable Capacity:** ~11.5 TB (after parity and formatting)
- **Filesystem:** ext4 / xfs (Optimized for NVMe throughput)

## **Network Configuration**
- **IP Address:** `10.0.10.3`
- **Subnet:** Perimeter (10.0.10.x)
- **Static DNS:** `nas.mostardesigns.com` (secondary pointer to `10.0.10.3`)
- **Physical Link:** Perimeter Switch Port 4

## **Services & Access**
- **SMB/CIFS:** Primary share for Windows/Mac clients.
- **NFS:** Optimized shares for Proxmox and The Home Assistant Server backups.
- **Power Management:** Controlled via **NAS1 MSNSwitch** (10.0.10.x) for remote hard-reboots.

### **Reliability Notes**
The use of 4x Team NVMe drives in RAID 5 provides a balance of high-speed random I/O and single-drive failure protection. The industrial eMMC prevents OS-level corruption common with standard consumer flash storage. The 10" rack-mount case ensures the unit remains secured and properly ventilated within the 9U cabinet.