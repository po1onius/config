;; Real-I/O test for the patched system.scm helpers.
;; - detection against real ext4/FAT images built with known UUIDs
;; - device-for-mount-point against the live /proc/self/mountinfo
(use-modules (rnrs bytevectors)
             (gnu build file-systems)
             (gnu system file-systems)
             (gnu system uuid)
             (ice-9 match)
             (ice-9 rdelim)
             (ice-9 format)
             (ice-9 popen))

(define (sh . args)
  (let* ((p (apply open-pipe* OPEN_READ args))
         (out (read-string p))
         (st (close-pipe p)))
    (unless (zero? (status:exit-val st)) (error "command failed" args))
    out))

(define (read-all port)
  (let loop ((forms '()))
    (let ((form (read port)))
      (if (eof-object? form) (reverse forms) (loop (cons form forms))))))

(define (helper-name form)
  (let ((head (cadr form))) (if (pair? head) (car head) head)))

(define wanted '(uuid-bytes->uuid device-for-mount-point read-uuid-by-label detect-uuid))

(define cfg (call-with-input-file "../system.scm" read-all))
(define helpers
  (filter (lambda (f)
            (and (pair? f) (memq (car f) '(define define*))
                 (memq (helper-name f) wanted)))
          cfg))
(for-each (lambda (h) (eval h (interaction-environment))) helpers)
(format #t "loaded helpers: ~s~%" (map helper-name helpers))

;; --- device-for-mount-point against the live mount table --------------------
(for-each (lambda (mp)
            (format #t "mount-point ~16a -> ~s~%" mp (device-for-mount-point mp)))
          '("/" "/boot/efi" "/gnu/store" "/nonexistent-mount"))
(format #t "list lookup  ~16a -> ~s~%"
        '("/nonexistent" "/boot/efi" "/")
        (device-for-mount-point '("/nonexistent" "/boot/efi" "/")))
(format #t "list miss    ~16a -> ~s~%"
        '("/nope" "/nope2")
        (device-for-mount-point '("/nope" "/nope2")))

;; --- detection against real filesystem images ------------------------------
;; Build the images in a temp dir: this script may live on a read-only checkout.
(define work-dir (or (getenv "TMPDIR") "/tmp"))
(define ext4-img (string-append work-dir "/uuid-verify-root.img"))
(define fat-img  (string-append work-dir "/uuid-verify-esp.img"))
(define ext4-uuid "8644af7e-f898-439f-87a6-5590b990c1b5")
(define fat-uuid  "9074-DBF7")

(unless (file-exists? ext4-img)
  (sh "truncate" "-s" "32M" ext4-img)
  (sh "mke2fs" "-q" "-t" "ext4" "-U" ext4-uuid "-L" "GUIX_ROOT" "-F" ext4-img))
(unless (file-exists? fat-img)
  (sh "truncate" "-s" "8M" fat-img)
  (sh "mkfs.fat" "-F" "32" "-i" "9074DBF7" "-n" "GUIX_ESP" fat-img))

(format #t "blkid root  : ~a" (sh "blkid" "-s" "UUID" "-o" "value" ext4-img))
(format #t "blkid esp   : ~a" (sh "blkid" "-s" "UUID" "-o" "value" fat-img))

(define root (detect-uuid 'ext4 #:device ext4-img))
(define esp  (detect-uuid 'fat32 #:device fat-img))
(format #t "detect root : ~s~%" (file-system-device->string root #:uuid-type 'ext4))
(format #t "detect esp  : ~s~%" (file-system-device->string esp #:uuid-type 'fat32))
(format #t "root == literal: ~s~%" (uuid=? root (uuid ext4-uuid 'ext4)))
(format #t "esp  == literal: ~s~%" (uuid=? esp (uuid fat-uuid 'fat32)))

;; A 4-byte FAT UUID must not be accepted as a DCE UUID.
(format #t "esp as ext4 : ~s~%" (false-if-exception (detect-uuid 'ext4 #:device fat-img)))

;; #:mount-point resolution itself works; the device behind the real "/" is
;; simply not readable inside this sandbox, so the read must fail loudly.
(format #t "real / via mount-point : ~s~%"
        (false-if-exception (detect-uuid 'ext4 #:mount-point "/")))
(format #t "bad mount-point         : ~s~%"
        (false-if-exception (detect-uuid 'ext4 #:mount-point "/no/such/mp")))

;; Failures must be loud.
(format #t "missing dev : ~s~%" (false-if-exception (detect-uuid 'ext4 #:device "/dev/nope")))
(format #t "no args     : ~s~%" (false-if-exception (detect-uuid 'ext4)))
(format #t "bad label   : ~s~%"
        (false-if-exception (detect-uuid 'ext4 #:label "NO_SUCH_LABEL")))
