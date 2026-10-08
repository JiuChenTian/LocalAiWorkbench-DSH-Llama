# r8：Harness 0.2.0 本地读图 400 修复

用户 r7 的 Harness 实际版本为 0.2.0-rc.2。会话错误为 `400: Failed to load image or audio file`；会话附件的文件头确认为 RIFF/WEBP。携带同一历史图片的后续请求会继续失败，不能据此判断所有文字调用均不兼容。

本机使用随包 upstream b11120、RTX 5090、Huihui-Qwen3-VL-8B-Instruct-abliterated.Q4_K_M 和匹配 mmproj 对照：同一测试图片 WebP 返回 400，PNG 返回 200。

工作台启动 Harness 时注入自己的本地图片请求适配模块；只对回环地址的 OpenAI chat/completions、responses POST 请求，将图片内容中的 WebP 转为 PNG。原始附件、会话文件、Harness 安装文件和版本锁不修改。非回环 API、文字内容、模型选择及 token 参数不改。重复历史图片使用有界内存缓存，不重复转换；用户取消仍有效。升级或回滚后启动 Harness 时仍会加载适配模块。

验证：83/83 .NET 测试通过；Node 测试覆盖图片转换、远程 API 隔离、历史缓存、请求头、Request 输入、IPv6、Responses 和取消。Harness 0.2.0-rc.2 使用真正的 read_image 工具读取测试 WebP，日志记录转换为 PNG，回答 Red，退出码 0。证据目录：artifacts/harness-vision-r8-verified/logs。用户安装目录只读，测试配置和会话放在项目隔离目录。

针对现有 r7 的补丁只含 app/Workbench.Infrastructure.dll：先退出工作台，再解压到 r7 根目录覆盖同名文件。它不替换已经更新的 Harness、模型库登记或会话。完整 r8 包用于新目录，仍携带锁定的 Harness 基线，可在管理页升级。

上游同类报告：https://github.com/deepseek-ai/deepseek-harness/discussions/4420 。本次根因与修复另有上述本机对照和真实 Harness 调用验证。
