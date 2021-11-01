1. 安装rz/sz:
    brew install lrzsz

2. 把本脚本放置在/usr/local/bin目录，并设置可执行权限:
    chmod +x /usr/local/bin/iterm2-zmodem.sh

3. 在iTerm2里添加两个触发器: 'Preferences...' -> 'Profiles' -> 'Advanced' -> 'Trigger', 单击 'Edit', 单击左下角“+”号
    触发器参数如下:
    Regular expression: rz waiting to receive.\*\*B0100
    Action: Run Silent Coprocess
    Parameters: /usr/local/bin/iterm2-zmodem.sh send
    Instant: checked

    Regular expression: \*\*B00000000000000
    Action: Run Silent Coprocess
    Parameters: /usr/local/bin/iterm2-zmodem.sh recv
    Instant: checked
