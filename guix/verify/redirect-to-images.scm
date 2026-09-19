;; Rewrite a guix/system.scm so its (file-system …) devices read images
;; instead of scanning /dev: the label lookup is shadowed to map ROOT/BOOT
;; onto the given image files.
;;
;;   guile redirect-to-images.scm <config> <root.img> <boot.img> > out.scm
(use-modules (ice-9 pretty-print)
             (srfi srfi-1))

(define args (cdr (command-line)))
(define config (list-ref args 0))
(define root-img (list-ref args 1))
(define boot-img (list-ref args 2))

(define (read-all port)
  (let loop ((forms '()))
    (let ((form (read port)))
      (if (eof-object? form) (reverse forms) (loop (cons form forms))))))

(define (redirect fs)
  (let* ((point (cadr (assq 'mount-point (cdr fs))))
         (img (cond ((equal? point "/") root-img)
                    ((equal? point "/boot/efi") boot-img)
                    (else #f))))
    (if img
        (map (lambda (f)
               (if (and (pair? f) (eq? (car f) 'device))
                   (list 'device
                         (list 'uuid-by-label
                               (if (equal? point "/") '%root-label '%boot-label)
                               (list 'quote (if (equal? point "/") 'ext4 'fat32))))
                   f))
             fs)
        fs)))

(define (rewrite x)
  (cond ((and (list? x) (pair? x) (eq? (car x) 'file-system)) (redirect x))
        ((list? x) (map rewrite x))
        (else x)))

(display "(use-modules (gnu build file-systems))\n")
(display "(define real-find find-partition-by-label)\n")
(format #t "(set! find-partition-by-label (lambda (label) (cond ((string=? label \"ROOT\") ~s) ((string=? label \"BOOT\") ~s) (else (real-find label)))))\n"
        root-img boot-img)
(for-each (lambda (f) (pretty-print (rewrite f)) (newline))
          (read-all (open-input-file config)))
