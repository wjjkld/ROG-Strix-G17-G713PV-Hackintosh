# ASUS ROG Strix G17 (G713PV) 黑苹果 · OpenCore EFI

**macOS Sequoia 15 · Ryzen 9 7940HX · RTX 4060 Laptop（独显直连） · 内置 Wi-Fi 与喇叭可用**

> **English summary:** OpenCore EFI for the ASUS ROG Strix G17 **G713PV** (2023, Ryzen 9 7940HX, RTX 4060 Laptop in MUX/dGPU mode, MediaTek MT7922 Wi-Fi, Cirrus CS35L41 speaker amps). Runs macOS Sequoia 15 with NVIDIA acceleration via NullMoth, native Wi-Fi via AirportMtkWlan, working internal speakers via CirrusAudioFixup (G713 support upstreamed in [hoaug-tran/CirrusAudioFixup#22](https://github.com/hoaug-tran/CirrusAudioFixup/pull/22)), an 80% battery charge limit, AMD CPU power management and ASUS Fn keys. **You must generate your own SMBIOS** (serial/MLB/ROM/UUID are placeholders). Keyboard backlight control does not work. Use at your own risk.

---

## 目录

- [硬件配置](#硬件配置)
- [工作状态](#工作状态)
- [使用前必读](#使用前必读)
- [BIOS 设置](#bios-设置)
- [安装步骤](#安装步骤)
- [EFI 说明](#efi-说明)
- [常见问题](#常见问题)
- [致谢与许可](#致谢与许可)

---

## 硬件配置

| 部件 | 型号 | macOS 下 |
|---|---|---|
| 机型 | ASUS ROG Strix G17 **G713PV**（2023） | — |
| CPU | AMD Ryzen 9 7940HX（Zen 4，16 核 32 线程） | ✅ AMD_Vanilla 补丁 + 电源管理 |
| 独显 | NVIDIA GeForce RTX 4060 Laptop（10DE:28E0） | ✅ **需开独显直连**，NullMoth 驱动加速 |
| 核显 | AMD Radeon 610M | ❌ 已屏蔽（不支持） |
| 内存 | 16 GB DDR5 | ✅ |
| 硬盘 | WD SN560 1 TB NVMe | ✅ |
| 有线网卡 | Realtek RTL8111/8168 | ✅ |
| 无线网卡 | MediaTek MT7922（AMD RZ616，14C3:0616） | ✅ AirportMtkWlan |
| 蓝牙 | MediaTek MT7922 | ⚠️ 已加载固件，未详细测试 |
| 声卡 | Realtek ALC294（layout-id 13） | ✅ |
| 功放 | 2 × Cirrus Logic CS35L41（I2C，子系统 1043:1D1F） | ✅ CirrusAudioFixup |
| 触控板 | I2C HID | ✅ VoodooI2C |
| 键盘 | ASUS N-KEY USB（0B05:19B6） | ✅ 按键正常，❌ 背光无法调节 |

## 工作状态

均为作者本机实测（macOS Sequoia 15）：

| 功能 | 状态 | 说明 |
|---|---|---|
| 显卡加速 | ✅ | 独显直连 + NullMoth NVIDIA 驱动（需在 macOS 内另装，见下文） |
| 内置喇叭 | ✅ | CirrusAudioFixup 1.2.1，G713 支持已合入上游 |
| 麦克风 | ✅ | |
| Wi-Fi | ✅ | AirportMtkWlan 2.0.0（Sequoia 版），系统原生 Wi-Fi 菜单 |
| 有线网络 | ✅ | |
| 触控板 | ✅ | |
| 80% 充电上限 | ✅ | 自写 SSDT-CHGLIMIT + AsusSMC，`pmset -g batt` 显示 "not charging" 即生效 |
| CPU 电源管理 | ✅ | AMDRyzenCPUPowerManagement，可用 AMD Power Gadget 查看频率和温度 |
| Fn 快捷键 | ✅ | AsusSMC（亮度、音量、媒体键、触控板开关） |
| 键盘背光调节 | ❌ | ROG 背光由 USB 键盘本身控制，AsusSMC 无法操作；在 Windows 里设好亮度会保持 |
| 麦克风静音、风扇模式、飞行模式键 | ❌ | AsusSMC 不处理这几个按键 |
| 睡眠 / 唤醒 | ❓ | 未充分测试 |
| HDMI / 摄像头 / 读卡器 | ❓ | 未测试 |
| AirDrop / 接力 | ❌ | MediaTek 网卡暂不支持 |
| 核显（Radeon 610M） | ❌ | 不支持，独显直连模式下用不到 |

## 使用前必读

1. **必须生成你自己的 SMBIOS。** `config.plist` → `PlatformInfo` → `Generic` 里的 `SystemSerialNumber`、`MLB`、`ROM`、`SystemUUID` 都是占位值。请用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成 **MacBookPro16,2** 的新值并填入，否则无法使用 iCloud / iMessage。不要使用别人的序列号。
2. **必须开启独显直连（MUX）。** 在 Windows 的 Armoury Crate 里把 GPU 模式切换为"独显直连 / Ultimate"并重启。macOS 只能使用 4060，核显模式下会黑屏。
3. **NVIDIA 显卡驱动不在 EFI 里。** 显卡加速依赖 [NullMoth](https://nullmothsystems.com) 的驱动，需要在 macOS 里用它的 1401 应用另外安装（免费，非商业许可）。EFI 中的 boot-args、`csr-active-config`、`SecureBootModel=Disabled` 等都是为这个驱动准备的。
4. **关闭 macOS 自动更新。** 显卡驱动、Wi-Fi 驱动（分 Sequoia / Tahoe 版本）都和系统版本强相关。小版本更新也可能导致黑屏或断网。等社区确认新版本可用后再手动升级。
5. **只针对 G713PV。** 其他型号（包括同系列的 G713PI / G713PU / G733 等）的子系统 ID、ACPI 表、功放和网卡可能不同，不要直接使用。充电上限 SSDT 和功放驱动都依赖本机的 ACPI 结构。
6. 系统完整性保护（SIP）部分关闭（`csr-active-config = 0x0A43`），这是第三方显卡驱动的要求，请了解其安全影响。

## BIOS 设置

开机时按 **F2** 进入 BIOS（Advanced Mode），修改后按 **F10** 保存。

| 选项 | 设置 | 说明 |
|---|---|---|
| Secure Boot | **关闭** | Boot → Secure Boot → OS Type 选"Other OS" |
| CSM | **关闭** | 只能纯 UEFI 启动 |
| Above 4G Decoding | **开启** | NVIDIA 驱动需要 |
| Resizable BAR | **开启** | NVIDIA 驱动需要，否则停在启动文字 |
| Fast Boot（BIOS 内） | 关闭（建议） | 避免识别不到 U 盘 |
| IOMMU | 关闭（如果有该选项） | AMD IOMMU 可能导致启动早期卡死 |
| XHCI Hand-off | 开启（如果有该选项） | |

开启了 BitLocker 的 Windows，改 BIOS 前请先暂停 BitLocker 或保存好恢复密钥。

## 安装步骤

1. **准备 U 盘（≥ 16 GB）**：格式化为 FAT32，把本仓库的 `EFI` 文件夹复制到 U 盘根目录。
2. **下载恢复镜像**：用 OpenCore 自带的 `macrecovery.py` 下载 Sequoia 恢复镜像，放到 U 盘的 `com.apple.recovery.boot` 文件夹：
   ```bash
   python macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download
   ```
   板号来自 [Dortania 指南](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/windows-install.html)。也可以直接用 NullMoth 1401 制作安装 U 盘。国内网络下载可能卡住。如果开了代理，留意 `oscdn.apple.com` 有没有被分流到直连。
3. **填好 SMBIOS**（见[使用前必读](#使用前必读)第 1 条）。
4. **给 macOS 准备分区**：可以和 Windows 装在同一块硬盘上。在 Windows 里压缩出空闲空间，或新建一个 exFAT 分区作为占位，在 macOS 安装程序的磁盘工具里**只抹掉这个分区**为 APFS。不要抹掉整块硬盘。
5. **从 U 盘启动**：开机按 **Esc**，选择 U 盘，在 OpenCore 菜单中选择恢复镜像，按正常流程安装。期间会重启几次，每次都选"macOS Installer"，直到出现"Macintosh HD"。
6. **安装显卡驱动**：进入系统后，用 NullMoth 1401 安装 NVIDIA 驱动。
7. **把 EFI 复制到硬盘的 EFI 分区**（和 Windows 的 `Microsoft` 文件夹放在一起），然后在 BIOS 里把 OpenCore（`\EFI\BOOT\BOOTx64.efi` 或 `\EFI\OC\OpenCore.efi`）加为启动项。建议保留一个装有可用 EFI 的 U 盘作为备用启动盘。

**双系统时间差 8 小时**：在 Windows 里把时间改为按 UTC 存储（管理员权限运行）：
```bat
reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_QWORD /d 1 /f
```

## EFI 说明

### Kext

| Kext | 版本 | 用途 | 来源 |
|---|---|---|---|
| Lilu | 1.7.3 | 补丁框架 | [acidanthera/Lilu](https://github.com/acidanthera/Lilu) |
| VirtualSMC / SMCBatteryManager / SMCLightSensor | 1.3.9 | SMC 仿真、电池 | [acidanthera/VirtualSMC](https://github.com/acidanthera/VirtualSMC) |
| WhateverGreen | 1.7.2 | 显示相关修复 | [acidanthera/WhateverGreen](https://github.com/acidanthera/WhateverGreen) |
| AppleALC | 1.9.9 | 声卡（ALC294，layout-id 13） | [acidanthera/AppleALC](https://github.com/acidanthera/AppleALC) |
| RestrictEvents | 1.1.7 | CPU 名称显示等 | [acidanthera/RestrictEvents](https://github.com/acidanthera/RestrictEvents) |
| NVMeFix | 1.1.4 | NVMe 电源管理 | [acidanthera/NVMeFix](https://github.com/acidanthera/NVMeFix) |
| BrightnessKeys | 1.0.4 | 亮度键 | [acidanthera/BrightnessKeys](https://github.com/acidanthera/BrightnessKeys) |
| AppleMCEReporterDisabler | 1.2 | 防 AMD 平台内核崩溃 | [acidanthera](https://github.com/acidanthera/bugtracker/files/3703498/AppleMCEReporterDisabler.kext.zip) |
| AMFIPass | 1.4.1 | AMFI 兼容（第三方驱动需要） | [dortania/OpenCore-Legacy-Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher) |
| RealtekRTL8111 | 2.4.2 | 有线网卡 | [Mieze/RTL8111_driver_for_OS_X](https://github.com/Mieze/RTL8111_driver_for_OS_X) |
| **AirportMtkWlan** | 2.0.0（Sequoia 版） | MT7922 Wi-Fi | [Arxusion/AirportMtkWlan](https://github.com/Arxusion/AirportMtkWlan)（GPL-2.0，源码见原仓库） |
| BlueToolFixup | 2.7.3 | 蓝牙 | [acidanthera/BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM) |
| SimpleMtkBtFw | 1.0.0 | MediaTek 蓝牙固件 | laobamac（随 NullMoth 1401 附带） |
| USBToolBox + UTBDefault | 1.2.0 | USB（通用映射，未定制） | [USBToolBox/kext](https://github.com/USBToolBox/kext) |
| **VoodooI2C / VoodooI2CHID** | 2.9.1 | 触控板 + 功放 I2C 通道 | [hoaug-tran/VoodooI2C](https://github.com/hoaug-tran/VoodooI2C/tree/main)（main 分支 1a1ae9a，提供功放驱动所需的 I2C 接口） |
| **CirrusAudioFixup** | 1.2.1 | CS35L41 功放（内置喇叭） | [hoaug-tran/CirrusAudioFixup](https://github.com/hoaug-tran/CirrusAudioFixup)（develop 350d03e，作者 CI 编译的 Release 版） |
| **AMDRyzenCPUPowerManagement + SMCAMDProcessor** | 0.7.2 / 1.0.1 | CPU 调频、温度 | [trulyspinach/SMCAMDProcessor](https://github.com/trulyspinach/SMCAMDProcessor) |
| **AsusSMC** | 1.4.1 | Fn 键、电池保护 | [hieplpvip/AsusSMC](https://github.com/hieplpvip/AsusSMC) |

加载顺序要求：Lilu 在最前；VoodooI2C 系列要在 CirrusAudioFixup 之前；AMDRyzenCPUPowerManagement 要在 SMCAMDProcessor 之前。

### ACPI

| SSDT | 作用 |
|---|---|
| SSDT-EC、SSDT-USBX、SSDT-PLUG-ALT、SSDT-HPET | 常规笔记本补丁 |
| SSDT-XOSI | 让 ACPI 按 Windows 方式运行（配合 `_OSI → XOSI` 重命名） |
| SSDT-PNLF、SSDT-LID、SSDT-GPRW、SSDT-SleepHook、SSDT-WakeScreen | 背光、合盖、睡眠唤醒相关 |
| SSDT-USB-Reset | USB 控制器复位 |
| **SSDT-CHGLIMIT** | **80% 充电上限**，仅在 macOS 下生效。通过 ASUS 原生方法 `\_SB.ATKD.WMNB`（DEVS 0x00120057）设置。源码见 [`ACPI-Source/SSDT-CHGLIMIT.dsl`](ACPI-Source/SSDT-CHGLIMIT.dsl)，改 `CHLM` 的值可以调整上限 |

### 主要配置

- CPU：AMD_Vanilla 补丁，核心数已设为 16（`0x10`）
- `boot-args`：`-vi2c-force-polling nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4`。除了 `-vi2c-force-polling`（触控板），其余都是 NullMoth 显卡驱动需要的
  - 画面闪烁时可以加上 `-nvrmnoflip`
- `Kernel → Block`：`com.apple.iokit.IONDRVSupport`（NullMoth 要求）
- `DisableIoMapper = true`（Wi-Fi 驱动要求，在 AMD 平台上没有副作用）
- `DisableVariableWrite = true`：Ryzen 7000 系列安装到后期写固件变量会卡死，所以开启
- `SecureBootModel = Disabled`
- OpenCore 为 NullMoth 1401 附带的版本

### 应急开关（加到 boot-args）

| 参数 | 作用 |
|---|---|
| `-mtkwlanoff` | 停用 Wi-Fi 驱动 |
| `-cirrusoff` | 停用功放驱动 |
| `-cirrusro -cirrusdbg` | 功放只读诊断模式（不出声，只检测芯片） |

## 常见问题

**喇叭不响？**
1. 系统设置 → 声音 → 输出，选择内置扬声器，而不是耳机。
2. 打开"音频 MIDI 设置"，把输出格式设为 **48,000 Hz**。
3. 在终端查看驱动状态：
   ```bash
   ioreg -lw0 -p IOService -r -c CirrusAudioFixup | grep -E 'Verdict|Cirrus_Bus|Detected_Amplifiers|DeviceID'
   ```
   正常情况下应该是 `Cirrus_Bus = I2C`，`Detected_Amplifiers = 2`，两个 DeviceID 都是 `0x35A40`。

**Wi-Fi 搜不到网络或掉线？**
确认 `config.plist` 里没有启用任何屏蔽网卡的 SSDT（本 EFI 已经删掉了 `SSDT-PCI-DISABLE-IOName`）。上游已知问题：RZ616 偶尔扫描失败，以及连上几分钟后掉线，见 [AirportMtkWlan issues](https://github.com/Arxusion/AirportMtkWlan/issues)。

**充电上限没生效？**
在终端运行 `pmset -g batt`，电量到 80% 后应该显示 `AC attached; not charging`。完全断电（拔掉电源且电池耗尽）后，EC 会忘记这个设置，下次进入 macOS 时会自动重新设置。

**启动卡住或黑屏？**
先检查 BIOS 设置和独显直连模式。在 OpenCore 菜单中按 `Cmd/Win + V`，可以开启啰嗦模式，看到卡在哪一步。

## 致谢与许可

- [Acidanthera](https://github.com/acidanthera)：OpenCore、Lilu、VirtualSMC、AppleALC 等
- [AMD-OSX](https://github.com/AMD-OSX/AMD_Vanilla)：AMD 内核补丁
- [NullMoth](https://nullmothsystems.com)：NVIDIA 驱动与 1401 EFI 生成器（PolyForm Noncommercial 1.0.0，见 [`LICENSES/`](LICENSES)；`Tools/NullMothSafe.efi` 与随 1401 生成的组件按此许可分发）
- [hoaug-tran](https://github.com/hoaug-tran)：CirrusAudioFixup 与 VoodooI2C 分支（非商业许可，见 [`LICENSES/CirrusAudioFixup-LICENSE.txt`](LICENSES/CirrusAudioFixup-LICENSE.txt)）。本机支持经 [PR #22](https://github.com/hoaug-tran/CirrusAudioFixup/pull/22) 合入上游
- Cirrus Logic：CS35L41 固件与调校（[`LICENSES/Cirrus-firmware-LICENSE.txt`](LICENSES/Cirrus-firmware-LICENSE.txt)），来自 [linux-firmware](https://gitlab.com/kernel-firmware/linux-firmware)
- [Arxusion](https://github.com/Arxusion/AirportMtkWlan) 与 laobamac、flxxxxddd、pengubow 等：MediaTek Wi-Fi 驱动
- [trulyspinach](https://github.com/trulyspinach/SMCAMDProcessor)、[hieplpvip](https://github.com/hieplpvip/AsusSMC)、[VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)、[USBToolBox](https://github.com/USBToolBox)

本仓库中各组件遵循各自的许可证。**禁止用于商业用途**：不得出售本 EFI，也不得把它放进付费安装包，其中多个组件为非商业许可。本仓库仅供学习交流，使用风险自负，作者不对数据丢失或硬件损坏负责。
