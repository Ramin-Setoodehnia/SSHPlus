# SSHPlus Manager for OpenWrt
[![Visitor Badge](https://img.shields.io/badge/Chat%20on-Telegram-blue.svg)](https://t.me/peditx) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


**The first comprehensive SSH tunneling solution natively integrated with PassWall on OpenWrt systems**

---

## 🚀 Features
- 🔐 OpenSSH Server/Client integration
- 🌐 SOCKS5 Proxy (Port 8089) creation
- 🛡️ Full PassWall/PassWall2 integration
- 📊 Real-time connection monitoring
- 📜 User-friendly CLI management interface
- 🔄 Auto-reconnect functionality
- 🧩 Compatible with all OpenWrt-supported architectures

---


## ⚙️ Supported Architectures
SSHPlus supports all OpenWrt-compatible CPU architectures, including:

- `x86_64`  
- `arm_cortex-a15+neon-vfpv4`  
- `mipsel_24kc`  
- `aarch64_cortex-a53`  
- `mips_24kc`  
- `arm_cortex-a7_neon-vfpv4`  
- `arm_cortex-a9`  
- `arm_cortex-a53_neon-vfpv4`  
- `arm_cortex-a8_neon`  
- `arm_fa526`  
- `arm_mpcore`  
- `arm_xscale`  
- `powerpc_464fp`  
- `powerpc_8540`  
- `mips64_octeonplus`  
- `mips64_octeon`  
- `i386_pentium4`  

*Full compatibility list available in [OpenWrt documentation](https://openwrt.org/docs/guide-user/additional-software/package-installation)*

---

## 📥 Installation
Run this single command in your OpenWrt 24 terminal :

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Ramin-Setoodehnia/SSHPlus/main/Files/install_sshplus.sh)"

```

Run this single command in your OpenWrt 25 terminal :

```bash
wget -qO- https://raw.githubusercontent.com/Ramin-Setoodehnia/SSHPlus/main/Files/SSHPlus_v16_Compatible.sh | sh"

```


---

## 📜 About This Innovation
**SSHPlus** represents the first native implementation of:
- Full OpenSSH integration in OpenWrt
- CLI-based SSH tunnel management
- Automatic PassWall configuration
- Service persistence through init.d

*Developed specifically for OpenWrt's unique environment*

---

## 🔧 Requirements
- OpenWrt 21.02 or newer
- 8MB+ Free Storage
- Active Internet Connection

---

🧾 License

Licensed under Ramin.Setoodehnia License


