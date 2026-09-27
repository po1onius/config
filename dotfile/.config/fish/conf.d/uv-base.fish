# 仅在普通交互式终端中自动激活 base，保留 Guix 和已有虚拟环境的 PATH。
# 重复激活会通过 deactivate 恢复 _OLD_VIRTUAL_PATH，覆盖当前环境的路径。
if status is-interactive
    if not set -q GUIX_ENVIRONMENT; and not set -q VIRTUAL_ENV
        if test -f ~/.venvs/base/bin/activate.fish
            source ~/.venvs/base/bin/activate.fish
        end
    end
end
