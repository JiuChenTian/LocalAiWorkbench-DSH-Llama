当前 r8：修复 Harness 本地视觉请求中的 WebP 导致 llama 返回 400；原始附件和外部 API 保持不变。详见 docs/R8-HARNESS-VISION.md。

r7 更新修复：修复 Harness 更新 5 分钟被强制终止的问题；下载跟随 Windows 系统代理，增加实时下载活动、重试和缓存复用。详见 docs/R7-UPDATE-NETWORK.md。

r6 基础功能：本地默认 131072 / 65536；新增 llama 启动调参、q8_0 KV 优化、Harness 官方版本查询与多快照回滚。已有运行参数需保存并重启 llama 才生效。

# Harness 与 llama

便携版直接运行最外层 LocalAiWorkbench.exe。总览提供 Harness 和 llama 各自的启停按钮；两者互不绑定，可同时运行，停止任意一个不会停止另一个。退出整个程序会清理受管子进程。

llama 默认以路由模式启动，不预加载模型。服务默认网页 http://127.0.0.1:8080，OpenAI API 地址 http://127.0.0.1:8080/v1，模型列表 http://127.0.0.1:8080/v1/models。仅监听本机，不要求 API 密钥；客户端必须填写时可填 workbench-local。模型管理中登记的 GGUF 会生成路由预设，load-on-startup=false；请求模型时按需加载。推理服务页也可选择直接加载指定模型。

Harness 默认 3080，可先于 llama 启动。不预配置任何模型提供方、模型目录或默认模型；请在 Harness 设置中手动添加已在 llama 中运行成功的模型。启动后的本地端口不变，llama 重启不会因随机密钥变化而使连接失效。模型目录、默认模型和匹配变更会更新 llama 预设，并刷新运行中的路由列表；Harness 模型目录由使用者在其设置中独立维护。更改端口后需重启相关服务。

网页地址栏接受域名、HTTP/HTTPS 与本机地址。127.0.0.1 是本机回环地址；27.0.0.1 不是本机地址。受管 Harness 标签仍限定其自身端口，新网页标签可访问 llama 或第三方网站。

## 配置位置

便携包预装 [dshmarket](https://github.com/dsh-market/dsh-market) 1.66.6，入口为 Harness 网页“设置 → 插件市场”；依赖安装在 `.dsh/profiles/web/node_modules`，启用列表在该 profile 的 `package.json`。锁定 pnpm 10.34.6 位于 `runtime/pnpm/10.34.6`，只加入 Harness 子进程 PATH。插件市场可管理自己的插件，Harness 版本切换不覆盖该 profile。`cordis.patch.yml` 设置 `allowRestart: false`，重启请使用工作台总览开关。

便携版实际 DSH_HOME 为便携根目录的 .dsh。管理页显示完整路径，并提供打开当前配置、profiles、日志和工作台连接配置目录的按钮。开发或旧版数据根保持原 config/harness 路径，避免原数据位置突然改变。

本机已有 C:\Users\ASUS\.dsh 和 C:\Users\ASUS\.dsh-doctor 仅作为定位入口（按当前用户目录计算），不自动合并、复制凭据或修改原文件。.dsh-doctor 是本机已有诊断数据，不代表便携包内安装了额外 doctor 工具。

工作台生成的桌面集成文件位于 config/harness-desktop-*.json，不包含模型/API 配置；旧 harness-local-*.json 不再被加载，llama 预设为 config/llama-router.ini；运行日志在 logs。模型/API 的日常配置优先使用 Harness 自带设置。便携包不会携带开发配置、凭据或会话。

## 已验证范围

本机使用外部 b11060 与显式 CUDA 13.0 运行库，验证了 Harness 先启动、无模型 llama 路由启动、两服务同时运行、llama Web、Harness Node 读取空模型列表、各自独立停止。没有运行模型推理任务。包内另两套指定内核仍按用户范围仅报告缺失依赖，不自动安装或硬件适配。

## 版本锁定与更新

随包基线为 Harness 0.1.5-rc.3、Node 24.21.0。构建准备和打包仍校验基线依赖锁；安装后的版本操作仅影响 Harness，不更新 Node、Llama 或 FFmpeg。

Harness 管理显示当前版本、从官方 GitHub Releases 查询的最新版本（含预发布）、可选择回滚的快照列表。更新前先完整备份当前组件，再安装对应官方 npm 精确版本并校验，最后覆盖固定启动路径。多个快照保存在 components/deepseek-harness/snapshots；回滚前同样先保留当前版本。界面显示阶段、文件数、活动进度与已用时间。详见 R6-VALIDATION.md。

Harness 运行期间持有独占组件锁，阻止更新、回滚或另一个实例同时使用同一组件。配置、凭据、工作目录和会话在组件之外，版本切换不回退这些数据。原包维护/修复会跳过已受版本管理的 Harness，卸载完整保留该组件及备份；完整性由 Harness 的版本锁检查。

当前遥测和子代理/工作流入口仍被集成配置关闭；这些不是本次版本管理工作的范围。代码升级不代表启用了这些配置项。

实现依据：[npm install 的精确版本与依赖锁行为](https://docs.npmjs.com/cli/v11/commands/npm-install/)。
推理服务页提供配置文件路径与打开目录按钮：config/models.json 保存模型库；config/llama-router.ini 为每次扫描及启动自动生成的路由预设；config/llama-models.json 记录匹配结果和排除原因；config/inference.json 保存运行参数。同目录唯一 mmproj 默认关联到该目录各模型量化，并写入 llama 预设；多个同目录 mmproj 需在模型管理中确认。

本地 llama 模型的上下文默认 131072、最大输出默认 65536 token，可在运行参数页调整；此默认不作用于外部 API 模型，外部模型由对应 API 决定。网页模型标识使用 GGUF 文件名（去掉 .gguf），重名文件才附加区分后缀。

Harness 启动后自动打开并连接工作台标签，服务重启后自动重新连接。Harness 设置中的打开配置文件通过内置本地适配打开 .dsh/settings.yaml，使用系统记事本，无需配置 YAML 文件关联。


## 独立启动与手动接入（r4）

Harness 启动不读取 llama 状态、模型库或运行参数，不自动写入提供方、默认模型、上下文或输出限制。两个服务独立启停。先在 llama 验证模型，再在 Harness 的模型设置中添加 OpenAI 兼容提供方；服务地址 http://127.0.0.1:设置的llama端口，若字段要求 OpenAI Base URL，则填写 http://127.0.0.1:设置的llama端口/v1。模型 ID 使用 /v1/models 返回的文件名。

llama 仍按需加载、最多一个常驻模型，默认 GPU 层数 999；0 为 CPU 模式。GPU 运行库自动解析与设备检查见 r5 说明；请求 GPU 时不允许静默回退 CPU。缺失依赖仍报告而不自动安装。本地上下文默认 131072，最大输出默认 65536；Harness 的模型参数由用户自行设置。

## r5：RTX 5090 GPU 加载修复与实测

已复现 b11060 在隔离 PATH 下 --list-devices 返回 none，而显式加入本机 CUDA v13.0/bin/x64 后识别 RTX 5090。修复为：读取 ggml-cuda.dll 的 CUDA 导入文件名，优先内核同目录、System32 和显式目录，缺失时只查找 Program Files/NVIDIA GPU Computing Toolkit/CUDA 的标准 bin/x64 与 bin 目录；仅加入受管子进程 PATH，不修改系统环境，不复制或安装 CUDA。确实缺失时列出 DLL 名称。

GPU 层数大于 0 时解析实际设备并显式传 --device CUDA0（或检测到的 Vulkan 设备），无设备时明确报错，不静默使用 CPU。诊断记录 logs/gpu-runtime.json、gpu-devices.txt；服务日志记录模型卸载层数与缓冲区。0 仍为显式 CPU 模式，999 表示尽可能加载全部层；旧配置中的 1 只请求卸载一层，需要全层时请改为 999。

实测使用 D:/software/llama/b11060 与 Huihui-Qwen3-VL-8B-Instruct-abliterated 的 Q4_K_M、Q8_0，自动匹配 mmproj；没有手工传 CUDA 目录。两种量化均完成真实聊天生成，日志分别确认 offloaded 37/37 layers to GPU，模型 CUDA 缓冲区约 4455/7670 MiB。上下文保留 196608，KV CUDA 缓冲区 27648 MiB；整卡显存从 458 MiB 上升到 32128 MiB，停止回到 458 MiB。长上下文显存压力很高，Windows 可能使用共享内存，本次不修改用户指定默认值。两次模型切换均验证 /models 仅一个 loaded 条目。

Harness 与 llama 保持独立启动，模型/API 仍由用户在 Harness 中手动配置。自动化检查 77/77 通过。完整证据在开发工作区 artifacts/gpu-r5-final/logs，不将本机模型路径或测试配置复制到新便携包。