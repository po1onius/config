# UUID 自动检测的验证

`guix/system.scm` 里的文件系统 UUID 不再写死，而是在求值配置时用
`detect-uuid` 从设备上读出来（依次尝试文件系统标签、块设备、以及从
`/proc/self/mountinfo` 反查挂载点）。这里的两个脚本就是用来验证它确实
检测到了正确的 UUID。

## build-compare.sh —— 最有力的那条证据

思路：把**改动前**那份写死 UUID 的配置（从 git 历史里取）和**现在**这份
自动检测的配置，都指向同一组带着本机真实 UUID 的 ext4/FAT 镜像（镜像文件
代替块设备，因为只有 root 能读真设备），分别求值，然后比较系统 derivation。
两条配置算出的 derivation 完全相同，就说明"检测出来的 UUID"和"原来写死的
UUID"在配置里完全等价。

```sh
bash ~/config/guix/verify/build-compare.sh [工作目录]
```

期望输出结尾：

```
OK: identical system derivation - detected UUIDs == hard-coded UUIDs
```

## uuid-verify-io.scm —— 逐个函数验证

在本目录下运行，会：

1. 从 `../system.scm` 里原样抽出 `uuid-bytes->uuid`、`device-for-mount-point`、
   `read-uuid-by-label`、`detect-uuid` 四个函数并加载；
2. 用当前机器的 `/proc/self/mountinfo` 验证挂载点->设备的反查；
3. 现场创建 `verify-root.img`（ext4，UUID 与 `blkid` 对拍）和
   `verify-esp.img`（FAT32），验证 `detect-uuid` 读出的 UUID 与镜像上的
   真实 UUID 一致，并且与字面量 `uuid=` 相等。

```sh
cd guix/verify
guix repl < uuid-verify-io.scm
```

## 已知的、与本次改动无关的构建阻塞

在本机（根分区只读挂载）跑完整的 `guix system build guix/system.scm` 目前会
失败，但**改动前的配置也同样失败**——同一个 system derivation，两条配置算出
来就是同一个：

```
builder for '…-elogind-dbus-service-wrapper.drv' failed
i/o error: /gnu/store/5imm3ld63fybrphlydqz5pr54zzr7d6k-elogind-257.14/share/dbus-1/system-services: No such file or directory
```

即 store 里的 elogind 输出缺少 `share/dbus-1/system-services` 目录，导致
`etc.drv` 建不出来，属于 store 不一致，不是 UUID 的问题。要真正 `reconfigure`
的话，需要先修这个（例如重新构建/替换 elogind 那个 store 项）。
