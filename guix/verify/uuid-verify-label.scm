;; Verify the label-only uuid-by-label taken from the real config.
;;
;;   guix repl < uuid-verify-label.scm
;; Checks uuid-by-label against ext4/FAT images labelled ROOT/BOOT
;; (find-partition-by-label is stubbed to point at them), then the failure paths.
(use-modules (rnrs bytevectors)
             (gnu build file-systems)
             (gnu system file-systems)
             (gnu system uuid)
             (ice-9 format)
             (ice-9 rdelim)
             (ice-9 popen))

(define truncate "/run/current-system/profile/bin/truncate")
(define mke2fs   "/run/current-system/profile/sbin/mke2fs")
(define mkfsfat  "/run/current-system/profile/sbin/mkfs.fat")
(define blkid    "/run/current-system/profile/sbin/blkid")

(define (sh . args)
  (let* ((p (apply open-pipe* OPEN_READ args))
         (out (read-string p))
         (st (close-pipe p)))
    (if (zero? (status:exit-val st)) out "<failed>")))

(define (read-file p)
  (let loop ((acc '()))
    (let ((c (read-char p)))
      (if (eof-object? c) (list->string (reverse acc)) (loop (cons c acc))))))

(define (eval-all port)
  (let loop ((n 0))
    (let ((form (read port)))
      (if (eof-object? form) n (begin (eval form (interaction-environment))
                                     (loop (+ n 1)))))))

(define root-img "/tmp/verify-ROOT.img")
(define boot-img "/tmp/verify-BOOT.img")
(define root-uuid "8644af7e-f898-439f-87a6-5590b990c1b5")
(define boot-uuid "9074-DBF7")

;; ---- build the images -----------------------------------------------------
(unless (file-exists? root-img)
  (sh truncate "-s" "32M" root-img)
  (sh mke2fs "-q" "-t" "ext4" "-U" root-uuid "-L" "ROOT" "-F" root-img))
(unless (file-exists? boot-img)
  (sh truncate "-s" "8M" boot-img)
  (sh mkfsfat "-F" "32" "-i" "9074DBF7" "-n" "BOOT" boot-img))
(format #t "镜像 ROOT: 标签=~a UUID=~a~%"
        (string-trim-right (sh blkid "-s" "LABEL" "-o" "value" root-img))
        (string-trim-right (sh blkid "-s" "UUID" "-o" "value" root-img)))
(format #t "镜像 BOOT: 标签=~a UUID=~a~%"
        (string-trim-right (sh blkid "-s" "LABEL" "-o" "value" boot-img))
        (string-trim-right (sh blkid "-s" "UUID" "-o" "value" boot-img)))


;; ---- the helper itself, straight out of the config -----------------------
(define text (call-with-input-file (string-append (getcwd) "/../system.scm") read-file))
(define start (string-contains text "(define %boot-label"))
(define end (string-contains text "\n\n(operating-system"))
(call-with-input-string (substring text start end)
                        (lambda (p) (eval-all p)))
(format #t "~%配置里的常量: BOOT=~s ROOT=~s~%" %boot-label %root-label)

;; Point the label lookup at the images (what /dev/nvme0n1pX would be).
(define real-find find-partition-by-label)
(set! find-partition-by-label
      (lambda (label)
        (cond ((string=? label "ROOT") root-img)
              ((string=? label "BOOT") boot-img)
              (else (real-find label)))))

(define root (uuid-by-label "ROOT" 'ext4))
(define boot (uuid-by-label "BOOT" 'fat32))
(format #t "uuid-by-label ROOT ext4  -> ~s（期望 ~a）~%"
        (file-system-device->string root #:uuid-type 'ext4) root-uuid)
(format #t "uuid-by-label BOOT fat32 -> ~s（期望 ~a）~%"
        (file-system-device->string boot #:uuid-type 'fat32) boot-uuid)
(format #t "与字面量相等: ~s / ~s~%"
        (uuid=? root (uuid root-uuid 'ext4))
        (uuid=? boot (uuid boot-uuid 'fat32)))

(define fs (list (file-system (mount-point "/boot/efi") (device boot) (type "vfat"))
                 (file-system (mount-point "/") (device root) (type "ext4"))))
(format #t "生成的 file-system 记录: ~s~%"
        (map (lambda (f) (cons (file-system-mount-point f)
                               (file-system-device->string (file-system-device f))))
             fs))

;; ---- failure paths must be loud ------------------------------------------
(format #t "~%错误路径（都应该是 error）:~%")
(format #t "  标签不存在   : ~s~%" (false-if-exception (uuid-by-label "NOPE" 'ext4)))
(format #t "  类型长度不符 : ~s~%" (false-if-exception (uuid-by-label "BOOT" 'ext4)))
(format #t "  设备读不出   : ~s~%"
        (false-if-exception (uuid-by-label "/dev/does-not-exist" 'ext4)))
