# 基于高云 FPGA 的实时多音色合成电子乐器

Pocket Lab-F1 开发套件上的四复音电子琴，支持板载 DAC 音箱输出与 USB 串口电脑播放。两路可以同时使用，也可以通过音箱静音、播放器停止分别使用。音符合成、包络、琶音和演奏事件录制均在 FPGA 中完成；电脑负责接收 PCM、缓冲、重采样和播放。

## 功能

- 四声部，正弦、方波、三角波三种基础音色；每声部 ADSR 包络。
- K1～K7 演奏七个自然音，三档八度（C3～B5）。
- 自动上行琶音，三档速度；最长 120 秒或 2048 个事件的录制与回放，先到限者停止。
- 数码管与 LED 状态显示；录音保存在易失存储器，复位或断电清空。
- DAC1 与 USB 共用合成内核。电脑播放有缓冲延迟，不保证两路声音同步。

## 硬件与软件

本工程针对 **Pocket Lab-F1 主板及扩展板**，芯片 **GW1N-UV9EQ144C6/I5**，工程器件系列 **GW1N-9C**，50 MHz 时钟。其他板卡必须重新核对引脚与电气接口，不能直接下载。

- FPGA 工具：Gowin EDA Education 1.9.11.03（开发时使用的版本）。
- 仿真：ModelSim 10.1a（开发时使用的版本）。
- 电脑播放：Windows、Python 3.14、Tkinter，以及 `host/requirements.txt` 中的依赖；需可用的 CH340 串口驱动。
- 下载口 Type-C 用于 FPGA 下载；独立串口 Type-C 用于 PCM 数据。USB 播放不是 USB Audio Class 声卡。
- DAC 输出需有源 AUX 音箱与衰减隔直电路，见 [焊接说明及电路图](docs/hardware/ASSEMBLY.md)。不要把裸扬声器接到 DAC。

## 编译与下载

1. 下载或克隆完整仓库，保留目录结构。用 Gowin 打开 `dual_audio/f1_dual.gprj`。
2. 确认器件、顶层 `top_dual`，依次运行 Synthesis、Place & Route 和码流生成。约束已列入工程。
3. 生成文件为 `dual_audio/impl/pnr/f1_dual.fs`。下载前先将音箱静音，在 Programmer 中检测板卡，选择 **SRAM Program and Verify**，下载并核对校验成功。
4. SRAM 下载在断电后失效；本仓库流程不写 Flash。不要选错旧版工程顶层。

也可以在仓库根目录用 PowerShell 执行（把程序路径换成自己的安装位置）：

```powershell
& '你的Gowin安装目录/IDE/bin/gw_sh.exe' scripts/build_dual.tcl
```

## 电脑播放器

在仓库根目录执行：

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r host/requirements.txt
.\.venv\Scripts\python.exe host/player.py
```

在界面选择实际 CH340 串口、**460800** 波特率和声音输出设备，点击开始，音量从 20% 起逐步调整。`host/start_player.bat` 使用 PATH 中的 Python，需先在该环境安装依赖。

仅 DAC：停止电脑播放器；仅 USB：关闭或静音外部音箱；双输出：两者均开启。停止电脑播放不会停止 FPGA 合成或 DAC 输出。

## 演奏操作

SW4=0 是演奏页，K1～K7 对应 Do～Si；SW4=1 是控制页。物理拨杆 ON 方向须结合数码管状态确认。每次切页先松开所有按键。

| 控件 | 功能 |
|---|---|
| SW1/SW2 = 0/0、1/0、0/1 | 正弦、方波、三角波；1/1 回退正弦 |
| SW3 = 0/1 | 短/长包络 |
| 控制页 K1/K2 | 降/升八度 |
| 控制页 K3/K4 | 琶音开关/速度切换 |
| 控制页 K5 | 空片段开始录制；录制中停止保存；已有片段时保护原片段 |
| 控制页 K6 | 回放/停止；录制中停止保存并立即回放 |
| 控制页 K7 | 清空录音 |
| K8 | 全局复位，清空录音 |

详细演示、录制《小星星》及验收步骤见 [实物验收指南](docs/ACCEPTANCE_DEMO_DUAL.md)。

## 结构

```text
按键/开关 → 消抖、页面控制、琶音、事件录放 → 四声部 DDS + ADSR + 混音
                                                   ├→ DAC1 → 隔直衰减 → 有源音箱
                                                   └→ FIR / 8倍抽取 → PCM帧 → UART
                                                                            ↓
                                                              Python 接收、缓冲、播放
```

合成 PCM 为 100 kS/s、有符号 16 位；DAC 转换为 10 位偏移二进制。USB 路经过 191 抽头 FIR，输出 12.5 kS/s、16 位单声道，串口 460800、8N1。每帧 128 个样本，包含序号、样本位置和 CRC16。协议实现见 `host/protocol.py`。

| 目录 | 内容 |
|---|---|
| `src/` | RTL、正弦及 FIR 系数表；旧顶层也保留，供对照仿真使用 |
| `dual_audio/` | 当前双输出 Gowin 工程、ModelSim 入口 |
| `constraints/` | 引脚和时序约束；当前工程使用 f1_usb.cst 与 f1.sdc |
| `tb/` | 仿真测试平台 |
| `host/` | Python 播放器、协议解析、缓冲和单元测试 |
| `scripts/` | 构建、仿真与串口数据核验脚本 |
| `docs/` | 实物操作、电路和验证记录 |

## 验证

在仓库根目录运行（ModelSim 路径按实际安装修改）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test_dual.ps1 -Vsim 'C:/modeltech_10.1a/win32/vsim.exe'
python scripts/verify_sim.py
.\.venv\Scripts\python.exe -m unittest discover -s host/tests -v
```

五项 ModelSim 测试覆盖双路输出、录放、完整旋律与长录音；`verify_sim.py` 将仿真 UART 帧解码，与导出的 PCM 逐样本比较。日志在 `reports/dual_audio/`。既有构建和实物验证的范围、限制见 [验证记录](docs/VERIFICATION.md)，验收清单不表示所有项目均已实测通过。

## 开源与复用

项目自有代码采用 [MIT 许可证](LICENSE)。混音器复用及其流水线改编的来源见 [THIRD_PARTY.md](THIRD_PARTY.md)，上游 MIT 版权声明保留。代码包含 AI 辅助开发内容。

仓库提供可构建源码，不附带 Gowin/ModelSim 安装程序、许可证、Python 第三方库副本或预编译码流。使用者需自行安装开发工具，并重新编译核对目标板卡。
