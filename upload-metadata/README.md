# 完整安装目录上传说明

本次上传包含原始目录的所有 30,264 个文件，共 3,669,559,622 字节（约 3.42 GiB），包括隐藏项目、node_modules、runtime、temp、日志和配置。共记录 4,157 个子目录，11 个空目录用额外的 .gitkeep 保留。原仓库 README.md 保留。

8 个超过 50 MiB 的文件通过 Git LFS 存储，包括所有 4 个超过 100 MiB 的文件。网页展示的 LFS 指针不是完整二进制文件；使用安装了 Git LFS 的 Git 下载：

```powershell
git lfs install
git -c core.longpaths=true -c core.autocrlf=false clone https://github.com/JiuChenTian/LocalAiWorkbench-DSH-Llama.git
cd LocalAiWorkbench-DSH-Llama
git lfs pull
powershell -ExecutionPolicy Bypass -File .\upload-metadata\Verify-Restore.ps1
```

`files-sha256.csv` 记录每个原始文件的相对路径、大小、SHA-256、Windows 属性和 UTC 修改时间。`directories.csv` 记录目录及属性，`summary.json` 为统计摘要。校验清单不包含新增的说明、校验工具、.gitattributes、.gitkeep 和原仓库 README.md。

Git 不存储 Windows 隐藏属性和原始时间。如需恢复，可在完成克隆后运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\upload-metadata\Verify-Restore.ps1 -RestoreAttributes
```

该选项先验证所有文件，再恢复清单中的文件/目录属性与修改时间；不会删除仓库附加文件。Git LFS 的下载受仓库账户的 LFS 配额限制。