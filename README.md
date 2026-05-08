# 面向小白的傻瓜式安装

# 1. 注册 DeepSeek 账号，获取 API Key
1. 登录：https://platform.deepseek.com 注册账号
2. 进入「API Keys」→ 新建密钥
3. 复制 sk-xxxxxx 格式密钥，在脚本执行过程中根据提示输入密钥，等待脚本执行完成即可

# 2. 安装
##  2.1 MacOS
1. 打开终端app
2. 将mac_install.sh拖进终端app
2. 然后输入 `chmod +x mac_install.sh` 回车
3. 继续输入 `./mac_install.sh` 回车
4. 执行过程中根据提示输入 `DeepSeek API Key（sk-开头）`

## 2.2 Windows 
1. 任意目录（桌面、磁盘任意路径下）新建文件夹，把 `windows_install.ps1` 和 `windows_install.bat` 两个文件放入
2. 双击 `windows_install.bat`
3. 执行过程中根据提示输入 `DeepSeek API Key（sk-开头）`


# 3. 使用claude
1. 打开终端app / PowerShell，输入 `claude` 回车，看到 claude 欢迎信息即表示可以正常使用
2. 设置基础配置
3. 按需安装 skill 或 plugin （问豆包，有手就行）
