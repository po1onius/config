(define-module (mihomo)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system copy))


(define-public mihomo-bin
  (package
    (name "mihomo-bin")
    (version "1.19.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/MetaCubeX/mihomo/releases/download/v"
                    version "/mihomo-linux-amd64-v" version ".gz"))
              (sha256
               (base32
                "0y3hwwzgiy81zjil3kgc1llz9s8hlbyy35ykr59za3fyc53l269q"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'((#$(string-append
                   "mihomo-linux-amd64-v" (package-version this-package))
                "bin/mihomo"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'fix-permission
                 (lambda _
                   (chmod (string-append #$output "/bin/mihomo") #o555))))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://wiki.metacubex.one/")
    (synopsis "Rule-based tunnel in Go")
    (description
     "This package provides @command{mihomo}, another @code{clash} kernel.")
    (license license:expat)))
