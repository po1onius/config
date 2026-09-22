# uv：PATH + Guix 上的 Python 来源设置
#
# uv 默认会下载 python-build-standalone 的预编译 CPython；那些二进制硬编码
# ELF 解释器 /lib64/ld-linux-x86-64.so.2，而 Guix System 没有 /lib /lib64
# （不是 FHS 布局），所以下载下来的 Python 起不来，uv 报：
#   error: Python interpreter not found at .../cpython-3.x-linux-x86_64-gnu/bin/python3.x
# 因此这里禁止 uv 使用/下载它自己管理的 Python，改用 Guix 提供的 Python。
set -gx UV_NO_MANAGED_PYTHON 1
set -gx UV_PYTHON_DOWNLOADS never

# uv tool install / uv python install 放置可执行文件的目录
if not contains ~/.local/bin $PATH
    set -gx PATH ~/.local/bin $PATH
end
