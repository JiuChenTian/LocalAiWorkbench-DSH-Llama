# 引擎包（drop-in 更新）· RTX 50 series / sm_120a · 2026-10-01

本包是**引擎级替换件**：给已经装了内测包 / 模型包的人用，**只换引擎与选卡器**，模型与文档都不用动。

```
engine-pack-p0warn-sm120a\
  engine\
    ninfer-serve-120a.exe       本架构引擎（**P0 补丁版**，见 §「本包改了什么」）
    pick-engine.bat   按本机显卡选引擎（**已修**，见 §「本包改了什么」）
    *.dll             CUDA 运行时 + ffmpeg/curl（免装 toolkit）
    自检-*.ps1 / 档位探针.ps1   自检脚本
  start-ptq1-mtp.bat  PTQ1_0 启动器（端口 8095）
  README-pack.md      本文件
  SHA256SUMS.txt      全包哈希对账表
```

## 怎么用（drop-in）

1. 把 `engine\` 整个覆盖到你现有内测包的 `engine\`（**只覆盖同名文件**；你的模型目录不动）。
2. 把 `start-ptq1-mtp.bat` 放进内测包根目录（**与模板包逐字节相同**，本来就有的话不用动）。
3. 双击 `start-ptq1-mtp.bat`；就绪判据：
   `curl.exe -s -o NUL -w "%{http_code}" http://127.0.0.1:8095/v1/models` 期望 **200**。

启动日志头两行应当打印本机算力与选中的引擎：

```
  Card   : compute capability <你的卡>
  Engine : ...\engine\ninfer-serve-120a.exe
```

## 本包改了什么（**只有两处**，实测确认）

与上一版引擎包对账，**只有 2 个文件不同**，其余逐字节相同：

| 文件 | 本包 sha256 | 上一版（`engine-pack-ptq1-sm120a`） |
|---|---|---|
| `engine\ninfer-serve-120a.exe` | `93411BCF337961F3BBF6528CEA040CE75DAF365787F64DE1C313271C4633C0BB` | `78C953A57BBC92F4D8D3B8445ED8168B3DD32DC00F24E9963F0E1FF7EC0B3024` |
| `engine\pick-engine.bat` | `CCE0709B79F75F1CE0DB0D01673F8A3600F44E7E7ABE24281E116CA2E76E0217` | `875E9A3665FC8304F17532973C905EB6BAF2FEA984B845DB32FE8B4111490B33` |

### 改动一 · 引擎：加了一条"超池告警"（**没有改任何行为**）

题面的 KV 占用**超过常驻设备池**时，日志里多打一行：

```
[warning] prompt exceeds the resident Device KV pool: prompt N tokens (P pages) > pool M tokens (Q pages) …
```

**为什么加它**：题面超池时，**题面中段的内容被实测会静默丢失**——HTTP 200、`finish_reason=stop`、
**日志零报错**，答案却像模像样。根因**至今未定位**，所以这一刀**只把"静默"消掉，不声称修复**。
看到那行告警 ⇒ **这条请求的答案不要当可信结果用**；把 `--kv-capacity` 提到 ≥ 题面 token 数再跑。

> ★ **本包启动器的 `--default-max-tokens` 是 32768，比池 17920 大**
> ⇒ **凡是不自带 `max_tokens` 的客户端，都会看到这行告警**。这不是故障，是实测的触发形状：
> 甲方口径里"客户端 `max_tokens` ≤ 池 token 数"就是这条。**想让它安静**：把启动器里那个值改到 ≤ 17920
> （**复制成 `.local.bat` 再改**，别动原件）。

### 改动二 · `pick-engine.bat`：修了一个**全卡型**的读卡 bug

原写法把 `nvidia-smi --query-gpu=compute_cap --format=csv,noheader` 放在 `for /f` 的命令串里，
**`=` 转义了、逗号没转义** ⇒ cmd 把命令按逗号拆开 ⇒ nvidia-smi 收到 `--format=csv` 加一个多余的 `noheader`
⇒ 报错 ⇒ **那段报错文本被当成算力值** ⇒ **受支持的卡被判"本包不支持你的架构"（退出 5）**
⇒ 四个 `start-*.bat` 全在引擎启动前退出（窗口一闪）。

本包这份已修，并加了守卫：**读数不是 `major.minor` 就拒绝（退出 3）**，绝不再把报错文本当卡号。

## 本包引擎的来源与验收

| 项 | 值 |
|---|---|
| 架构 | sm_120a（RTX 50 系，compute capability 12.0） |
| 构建 | 从**空目录全新构建**（干净构建目录），同一份源码树 |
| 打包机 | NVIDIA GeForce RTX 4080 SUPER / sm_89 / 32,760 MiB |
| 本架构运行级验收 | ⛔ **本机验不了**：打包机是 sm_89，120a 引擎在那里直接死于 `cudaErrorNoKernelImageForDevice`（与上一版冻结那支**逐字同签名** ⇒ 属架构，不属本补丁）⇒ **必须在 RTX 50 卡上跑一次判据** |

**判据工具**（本包未附带，在甲方发布目录里）：`verify-arch-engine.ps1`
—— 正控（题面超池）必须出 **1** 行告警、负控（装得下）必须 **0** 行；退出码 **2** = 引擎在该卡上起不来（没验成）、**4** = 引擎旁缺 DLL（工具拒绝）。

## 没验的（照抄本页请一起抄走）

| # | 事 | 为什么 |
|---|---|---|
| 1 | ★ 本架构的一切运行读数（这是本包发出来最主要的目的） | 打包机没有 50 系卡；`cudaErrorNoKernelImageForDevice` 说明二进制里没有本机的 kernel image，与补丁无关 |
| 2 | 超池"正中针"的**根因** | **未定位**；打包机 23 次请求（含 3.9× 超池、5 个深度）**一次没丢** ⇒ 本包交的是"把静默消掉"，**不是修复** |
| 3 | `--recover-invariant-failures` / `--kv-lease-growth` 实测 | 未排期（源码事实已核：两者默认关，而它们正是"崩实例 ⇒ 拒绝并继续服务"的现成开关） |
| 4 | n-gram 开/关 A/B | 未做 ⇒ 引用 tok/s 时必须同时报 `ngram_drafted_tokens` / `ngram_accepted_tokens` |

## 三条会让人误判的坑

1. **`/v1/models` 返回 200 ≠ 可服务** —— 它读静态清单，worker 死了照样 200。判就绪请用 `/health`（真查引擎，坏时 503）**加**一次真请求。
2. **客户端 `max_tokens` 别超过池 token 数** —— 池 17,920 时给 32,000，实测会**打崩 worker 且不自愈**（此后全 503，而 `/v1/models` 仍 200）。
3. **`--max-context` 开太大起不来** —— ring 语义下启动有一条守卫 `host_pages + pool_pages >= page_count(--max-context)`；
   实测撞过：`--max-context 262144` + `--host-kv-mib 16384` ⇒ 直接拒绝启动
   （`host_pages=2608 pool_pages=32 logical_pages=4096`）。自测用 `--max-context 65536` 不会撞。
