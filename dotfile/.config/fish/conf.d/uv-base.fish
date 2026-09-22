# 开交互式 shell 时自动激活 base 环境（类似 conda 的 base）
if status is-interactive; and test -f ~/.venvs/base/bin/activate.fish
    source ~/.venvs/base/bin/activate.fish
end
