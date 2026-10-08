# 第三方依赖（第二阶段）

| 项目 | 当前版本/状态 | 许可与来源 |
| --- | --- | --- |
| Microsoft.Web.WebView2 SDK | 1.0.4191.47，已使用 | Microsoft 软件许可；完整 LICENSE / NOTICE 复制于 `licenses/WebView2-SDK/`；https://www.nuget.org/packages/Microsoft.Web.WebView2/1.0.4191.47 |
| .NET / WPF | SDK 10.0.301 构建；可选自包含 Windows x64 10.0.9，默认开发包仍依赖系统运行时 | 自包含包从官方 NuGet 恢复 Microsoft.NETCore.App.Runtime.win-x64 / Microsoft.WindowsDesktop.App.Runtime.win-x64；原包 LICENSE、现有 THIRD-PARTY-NOTICES、版本、nuspec 与包摘要随输出保存在 `licenses/dotnet/`。https://github.com/dotnet/runtime/blob/main/LICENSE.TXT ，https://github.com/dotnet/wpf/blob/main/LICENSE.TXT |
| WebView2 Runtime | 可选收集本机 Evergreen 149.0.4022.98 x64 副本，用于内部预览；不是官方 Fixed Version 压缩包 | 已保留完整本机版本目录及其内置许可资源、show_third_party_software_licenses.bat，记录来源与逐文件摘要。主程序 Microsoft 签名有效；正式再分发材料、复制后加载与干净机器部署尚待验证。与 SDK 分开分发和许可；https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution |
| DeepSeek Harness / Node.js | npm @deepseek-ai/dsh 0.1.5-rc.3 / Node 24.21.0 已放入开发运行根 | 官方 npm 与 nodejs.org 下载，保留组件内 LICENSE；npm 依赖锁及摘要见 build/harness/package-lock.json，Node ZIP 摘要固定于 PrepareHarness.ps1。完整依赖许可/正式分发材料仍待整理，不宣称正式离线交付完成 |
| FFmpeg | 用户提供的 8.1.2-essentials_build，已导入开发运行根 | 包内 README 标注 gyan.dev Windows x64 static / GPL v3，源码提交 https://github.com/FFmpeg/FFmpeg/commit/38b88335f9；完整 LICENSE、README、doc、presets 随组件保留。正式分发前仍需准备该二进制及依赖对应的源码/构建材料，不以源码链接替代交付核查 |
| llama.cpp 上游 / PrismML | 可选内置用户提供的 b11120 / CUDA 13.4 与 prism-b10709-9a9394a / CUDA 13.3 本地 ZIP 内容，完整保留目录与包内许可文件 | 归档和逐文件摘要记录于各版本 kernel.json，摘要不等于官方来源认证。完整再分发材料及 CUDA 运行库许可仍待核对；不得把主体 MIT 许可当作 CUDA 等依赖许可 |

WebView2 NuGet 的完整性摘要保存在 `src/Workbench.Desktop/packages.lock.json`。SDK 许可不替代运行时、CUDA 或其他软件的再分发条款。正式安装包还需补齐实际分发的运行时、npm 依赖及 notices。
# 随便携版新增的插件市场

- dshmarket 1.66.6：[来源](https://github.com/dsh-market/dsh-market)，MIT；许可证随插件位于 `.dsh/profiles/web/node_modules/dshmarket/LICENSE`。
- pnpm 10.34.6：[来源](https://github.com/pnpm/pnpm)，MIT；完整包及许可位于 `runtime/pnpm/10.34.6/node_modules/pnpm`。
