;; Reconfigure inside WSL with:
;; sudo guix system reconfigure --skip-checks --no-bootloader --no-kexec /home/liz/guix/config.scm
(use-modules (gnu)
             (guix gexp)
             ((gnu packages) #:select (specifications->packages
                                      %package-module-path))
             ((gnu packages shells) #:select (fish))
             ((gnu system image) #:select (operating-system-for-image))
             (gnu system images wsl2))


;; Preserve the official image's generated file-system metadata so this
;; configuration also works with `guix system reconfigure`.
(define base-os
  (operating-system-for-image wsl2-image))

(operating-system
 (inherit base-os)
 (users
  (map (lambda (account)
         (cond
          ((string=? (user-account-name account) "guest")
           (user-account
            (inherit account)
            (name "liz")
            (comment "liz")
            (shell (file-append fish "/bin/fish"))
            (home-directory "/home/liz")))
          ((string=? (user-account-name account) "root")
           (user-account
            (inherit account)
            (shell (wsl-boot-program "liz"))))
          (else account)))
       (operating-system-users base-os)))
 (services
  (modify-services (operating-system-user-services base-os)
    (guix-service-type config =>
      (guix-configuration
       (inherit config)
       (substitute-urls
        (cons* "https://ci.guix.moe"
               (guix-configuration-substitute-urls config)))
       (authorized-keys
        (cons*
         (plain-file
          "ci-guix-moe.pub"
          "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))")
         (guix-configuration-authorized-keys config))))))))
