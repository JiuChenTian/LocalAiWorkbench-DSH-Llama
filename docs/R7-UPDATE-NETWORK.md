# r7：Harness 更新下载修复（2026-10-02）

r6 测试日志显示 npm 于 14:43:55 开始安装，持续收到 HTTP 200，在 14:48:55 被工作台的 5 分钟进程总时限终止。Chrome 能访问 GitHub，不代表 npm 的依赖下载能够在该时限内完成；实际依赖源为 registry.npmjs.org。

- 下载进程总时限改为 30 分钟，单次 HTTP 请求 120 秒、失败重试 2 次，支持取消并复用 npm 缓存。
- GitHub/npm 元数据请求和 npm 安装均读取当前 Windows 系统代理；开关 VPN 后重新操作会重新解析代理，不沿用旧进程环境代理。VPN 隧道模式按系统直连路径运行。仅 Chrome 扩展内设置的代理不属于 Windows 系统代理。
- 元数据短暂网络故障最多重试 2 次；不绕过 TLS 校验，不切换到第三方软件源。
- 下载阶段持续显示 HTTP 活动，失败区分元数据请求、依赖安装退出和总时限，并提供日志位置。
- 先备份后更新、精确版本和 SHA-512 校验、多快照回滚保持不变。

诊断日志：logs/harness-update.txt 与 cache/npm/_logs。完整自动化测试 83/83 通过，包含代理与直连切换、清除旧代理环境、实时错误流进度、取消和元数据重试。联网验收隔离目录：artifacts/harness-network-r7；用户 r6 安装目录只读检查，没有修改。
r7 最终交付完成：83/83 自动化测试、WPF 页面验收、空 npm 缓存下经 Windows 系统代理的真实下载、0.1.5-rc.3 → 0.2.0-rc.2 更新及新版 Web 启动均通过，隔离测试目录已经恢复原版。npm 正常退出 0，安装 536 个包。证据：artifacts/harness-network-r7/logs/harness-download-PASS.json、harness-update.txt。
便携 ZIP：artifacts/packages/LocalAiWorkbench-Portable-Windows-x64-20261002-r7.zip，976,935,589 字节；30,351 项 ZIP 文件逐项校验通过（含清单）。SHA-256：a164f11a1ab589ba658b78a285dd3772c681d8314f7a46502ad7cca67ebc0f7f。
没有替用户开关 VPN；当前系统代理的真实链路已验证，直连/代理切换和清除过时环境变量由自动化测试覆盖。用户仍需在自己的 VPN 两种状态下复测。