# UUID 自动检测（按固定标签）

`guix/system.scm` 里不再写死 UUID，也不依赖 `/dev/nvme0n1pX` 这类设备名：
求值配置时按**固定标签**去盘上找这两个文件系统，读出它们的 UUID。

| 挂载点 | 标签 | 类型 |
|---|---|---|
| `/` | `ROOT` | ext4 |
| `/boot/efi` | `BOOT` | FAT32 |

配置里就两行：

```scheme
(device (uuid-by-label %boot-label 'fat32))   ; %boot-label = "BOOT"
(device (uuid-by-label %root-label 'ext4))    ; %root-label  = "ROOT"
```

## 先给磁盘打标签

**必须先把标签打好再 reconfigure**，否则 `uuid-by-label` 会直接报错
（它找不到标签就不会继续，这是故意的）。Ext4 和 FAT 的标签都能在挂载状态下改：

```sh
# 根文件系统（ext4）
sudo e2label /dev/nvme0n1p2 ROOT

# EFI 系统分区（FAT32）；fatlabel 会把标签写进 BPB，UEFI 固件看的是分区 GUID，
# 不受影响
sudo fatlabel /dev/nvme0n1p1 BOOT

# 确认
blkid -s LABEL -s UUID /dev/nvme0n1p1 /dev/nvme0n1p2
ls /dev/disk/by-label/
```

全新安装时直接在 mkfs 阶段打上即可：

```sh
mkfs.ext4 -L ROOT  /dev/xxx2
mkfs.fat  -F 32 -n BOOT /dev/xxx1
```

## 求值前提

读超级块需要 **root**，设备节点也必须存在（udev 就绪）：

```sh
sudo guix system reconfigure ~/config/guix/system.scm
```

## uuid-verify-label.scm

```sh
cd guix/verify
guix repl < uuid-verify-label.scm
```

现场造两个镜像（ext4 标签 `ROOT`、FAT32 标签 `BOOT`，UUID 用本机真实值），
把 `find-partition-by-label` 指向它们，然后验证：

- `uuid-by-label` 读出的就是 `8644af7e-…` 和 `9074-DBF7`，与字面量 `uuid=` 相等；
- 生成的 `file-system` 记录里的 device 字符串正确；
- 三种错误路径（标签不存在 / 类型字节数不符 / 设备读不出）都会 `error`，
  而不是静默返回 `#f`。

## build-compare.sh

```sh
bash ~/config/guix/verify/build-compare.sh [工作目录]
```

拿 git 历史里那份写死 UUID 的配置做 baseline，两份配置都指向同一组镜像，
比较求值出的 system derivation 是否相同——相同就说明"标签解析出的 UUID"和
"原来写死的 UUID"完全等价。

## 已知的、与本次改动无关的构建阻塞

本机（根分区只读挂载）跑完整 `guix system build` 会卡在：

```
builder for '…-elogind-dbus-service-wrapper.drv' failed
i/o error: /gnu/store/…-elogind-257.14/share/dbus-1/system-services: No such file or directory
```

store 里的 elogind 输出缺少 `share/dbus-1/system-services`，`etc.drv` 因此建不出来。
改动前的配置也是同样结果，属于 store 不一致，不是 UUID 的问题。
