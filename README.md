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
Run this single command in your OpenWrt terminal:

```bash
rm -f *.sh && wget https://raw.githubusercontent.com/Ramin-Setoodehnia/SshPlus/refs/heads/main/Files/install_sshplus.sh && sh install_sshplus.sh

```

---

## ✨ Key Capabilities
1. **Secure SSH Tunneling**  
   Create encrypted SOCKS5 proxies with military-grade AES-256-GCM encryption

2. **PassWall Integration**  
   Direct integration with popular OpenWrt proxy solutions

3. **Connection Management**  
   ```
   sshplus  # Launch management interface
   ```
   - Start/Stop tunnels
   - Edit configurations
   - Monitor active connections

4. **Auto-Service Creation**  
   Persistent connections survive reboots via init.d service

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
- 8MB+ free storage
- Active internet connection

---

## 📬 Support & Contact
**Telegram Channel:**  
[https://t.me/peditx](https://t.me/Ramin-Setoodehnia)

---

## 📄 License
**Copyright © 2025 Ramin-Setoodehnia**  
*This project is licensed under the GPL-3.0 License*

