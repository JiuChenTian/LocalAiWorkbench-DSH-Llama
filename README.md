# LocalAiWorkbench-DSH-Llama

Windows x64 便携本地 AI 工作台：以 DeepSeek Harness 为基础，集成了 llama 入口和 ninfer 入口，可以通过压缩包导入自己需要的引擎并使用（llama 主分支和 prism 分支、ninfer 分支），可以指定模型总文件路径。

> 当前为内部开发预览版（internal-development-preview），未签名。无需安装、无需管理员权限、不写注册表：完整解压后直接双击最外层 `LocalAiWorkbench.exe` 即可运行，整个目录可以移动。

## 简介

以 DeepSeek Harness 为基础，集成了 llama 入口和 ninfer 入口：

- 可以通过压缩包导入自己需要的引擎并使用（llama 主分支和 prism 分支、ninfer 分支）
- 可以指定模型总文件路径，模型文件夹规范如下：**总文件夹 - 模型文件夹 - 模型各种量化和视觉文件**
- gguf 和 ninfer 属于不同的模型，需要分别建立模型文件夹放置
- 配置、会话、缓存及日志均写入便携目录，外部模型目录仅作为引用，不随包分发模型文件

## 已内置

| 组件 | 版本 | 位置 |
| --- | --- | --- |
| DeepSeek Harness | 0.1.5-rc.3 | `components/deepseek-harness/` |
| Node.js | 24.21.0 | `runtime/node/` |
| FFmpeg | 8.1.2 (essentials_build) | `components/ffmpeg/` |
| pnpm | 10.34.6（隔离） | `runtime/pnpm/`，仅加入 Harness 子进程 PATH |
| dshmarket 插件市场 | 1.66.6 | `.dsh/profiles/web/`，Harness 网页“设置 → 插件市场” |
| .NET 运行时 | 10.0.9（自包含） | `app/` 与 `licenses/dotnet/` |
| WebView2 | 149.0.4022.98（本机 evergreen 副本） | 见 `licenses/WebView2-SDK/` |

推理引擎内核未内置，默认不随包分发，可通过“导入引擎压缩包”按需导入。

## 已实现功能

1. **根据模型总目录识别模型**：指定模型总目录后自动扫描登记；同目录唯一 mmproj 默认关联到该目录各模型量化；量化标签取自文件名，未标注时可自定义。
2. **更新 DeepSeek Harness 至最新版本的同时备份当前版本**：从官方 GitHub Releases 查询最新版（含预发布），先完整快照备份当前组件，再安装官方 npm 精确版本并校验；备份未删除的情况下，可以选择回滚到任意已备份版本。
3. **自定义导入引擎压缩包并选择引擎文件**：支持导入 llama 主分支、prism 分支、ninfer 分支的引擎压缩包，导入后可选择引擎可执行文件。
4. **双服务独立管理**：总览页分别提供 Harness 和 llama 启停开关，可同时运行；停止任意一个不影响另一个，退出程序会清理受管子进程。
5. **llama 路由模式**：默认不预加载模型、按需加载，最多一个常驻模型；本地上下文默认 131072、最大输出默认 65536，可在运行参数页调整（外部 API 模型不适用，由对应 API 决定）。
6. **GPU 运行库自动解析**：GPU 层数默认 999（0 为显式 CPU 模式）；解析 CUDA 导入文件并检查设备，无设备明确报错，不静默回退 CPU；缺失依赖只报告，不自动安装。
7. **本机回环服务**：llama 默认 `http://127.0.0.1:8080`（OpenAI API 地址 `http://127.0.0.1:8080/v1`，模型列表 `/v1/models`）；Harness 默认 `http://127.0.0.1:3080`；两者端口必须不同。本机 llama 不要求 API 密钥，客户端必须填写时可填 `workbench-local`。

## 快速上手

1. 完整解压，双击最外层 `LocalAiWorkbench.exe`。
2. 如缺少引擎：在工作台导入引擎压缩包并选择引擎文件（llama 主分支 / prism 分支 / ninfer 分支）。
3. 在模型管理中指定模型总目录；按“总文件夹 - 模型文件夹 - 量化和视觉文件”的规范放置模型。
4. llama 以路由模式启动后登记模型，即可在 llama 网页或 Harness 中选择使用。
5. 在 Harness 设置中添加已在 llama 中运行成功的 OpenAI 兼容提供方：服务地址 `http://127.0.0.1:<llama端口>`，若字段要求 OpenAI Base URL 则填写 `http://127.0.0.1:<llama端口>/v1`；模型 ID 使用 `/v1/models` 返回的文件名。

## 模型目录规范

```
模型总文件夹/
└── 模型A文件夹/
    ├── 模型A-Q4_K_M.gguf
    ├── 模型A-Q8_0.gguf
    └── mmproj 视觉文件
```

- gguf（llama）与 ninfer 属于不同的模型，需要分别建立模型文件夹放置
- 网页模型标识使用 GGUF 文件名（去掉 `.gguf`），重名文件才附加区分后缀
- 同目录多个 mmproj 时优先按名称/系列匹配，其次按文件路径排序；可手动更改、禁用或恢复自动匹配，用户明确保存的选择优先

## 目录结构

最外层 `LocalAiWorkbench.exe` 是原生启动器，程序及 .NET DLL 放在 `app/`；移动时请保留整个目录：

- `app/`：工作台程序主体（LocalAiWorkbench、Workbench.Application/Domain/Infrastructure）
- `components/`：`deepseek-harness/`（含 `runtime.lock`、`snapshots/` 快照）、`ffmpeg/`、`llama.cpp/`（导入的引擎内核）
- `runtime/`：`node/`（Node.js 24.21.0）、`pnpm/`（10.34.6 隔离）
- `config/`：工作台与 llama 配置（见下）
- `cache/`：模型索引（`model-index.json`，含 `.backup`）
- `docs/`：版本说明（`R6-VALIDATION.md`、`R7-UPDATE-NETWORK.md`、`R8-HARNESS-VISION.md`、`R9-MODEL-DEFAULTS.md`、`HARNESS.md`）
- `licenses/`：.NET、WebView2 等随附许可
- `logs/`：`application.jsonl` 运行日志及 GPU 诊断
- `models/`、`downloads/`、`temp/`、`imports/`、`workspaces/`：用户数据，打包时排除
- `.dsh/`：便携 Harness 配置根目录（DSH_HOME）

## 配置文件说明

- `config/models.json`：模型库
- `config/llama-router.ini`：每次扫描及启动自动生成的路由预设
- `config/llama-models.json`：匹配结果和排除原因
- `config/inference.json`：运行参数（含 `inference.backup.json` 备份）
- `config/workspace.json`、`config/application.lock`：工作区与锁
- `logs/application.jsonl`：工作台日志；GPU 诊断在 `logs/gpu-runtime.json`、`logs/gpu-devices.txt`
- `.dsh/`：Harness 配置、profiles 与会话；管理页显示实际 DSH_HOME，并提供打开配置目录、profiles 和日志的按钮

## Harness 更新与回滚

- 管理页从官方 GitHub 查询最新版，先完整备份当前组件，再安装官方 npm 精确版本并校验，最后覆盖固定启动路径
- 多个快照保存在 `components/deepseek-harness/snapshots`，未删除备份时可选定回滚
- Harness 运行期间持有独占组件锁，阻止更新、回滚或另一实例同时使用同一组件
- 只更新 Harness，不更新 Node、llama 引擎、FFmpeg；配置、凭据、工作目录和会话不随版本回退
- 操作前请停止 Harness；界面显示阶段、文件数、活动进度与已用时间

## 限制与范围

- 本包为未签名内部预览，未做干净机验收
- 包内不带模型文件；若启动内核提示缺失 DLL，请在运行参数中指定已有依赖目录后重试，不会自动安装 CUDA 或修改系统环境
- 修改端口后需重启相关服务；已有运行参数需保存并重启 llama 才生效
- 开始使用或更新 Harness 后，请勿用原包清单修复整个目录
- 本包不重复实现 Harness 自带功能；Harness 的模型目录、默认模型由其设置独立维护

## License

本项目采用 MIT 许可证，详见 [MIT license](LICENSE)。

## 致谢

本工作台建立在众多优秀的开源项目与社区工作之上，谨向以下项目致谢：

- **DeepSeek Harness**（`@deepseek-ai/dsh`）：工作台内核，提供 Agent 运行时、Web GUI、插件体系与任务管理能力
- **llama.cpp**：本地推理引擎第一基础
- **ninfer**：本地推理引擎第二基础
- **dshmarket**（[dsh-market/dsh-market](https://github.com/dsh-market/dsh-market)）：Harness 插件市场，带来一键安装与生态扩展
- **FFmpeg**（8.1.2）：媒体处理支持
- **Node.js**（24.21.0）与 **pnpm**（10.34.6）：运行时与依赖管理
- **Microsoft .NET**（10.0.9）与 **WebView2**：工作台界面运行时
- **NVIDIA** CUDA / cuBLAS 及运行库：GPU 推理支持
- **ggml**：张量计算基础
- 感谢所有分享 GGUF / ninfer 模型的作者与量化工程师
