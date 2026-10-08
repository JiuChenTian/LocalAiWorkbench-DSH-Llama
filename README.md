# LocalAiWorkbench-DSH-Llama
以DeepSeekHarness为基础，集成了llama入口和ninfer入口，可以通过压缩包导入自己需要的引擎并使用（llama主分支和prism分支、ninfer分支），可以指定模型总文件路径，模型文件夹规范如下：总文件夹-A模型文件夹-A模型各种量化和视觉文件（gguf和ninfer属于不同的模型，需要分别建立模型文件夹放置）


# 已内置：
DeepSeekHarness 0.1.5、插件市场

# 已实现功能：
1、根据模型总目录识别模型

2、更新DeepSeekHarness至最新版本的同时备份当前版本、在未删除的情况下，可以选择回滚到已备份版本

3、自定义导入引擎压缩包并选择引擎文件
