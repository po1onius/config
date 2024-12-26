(define-module (helix)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix deprecation)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages crates-apple)
  #:use-module (gnu packages crates-crypto)
  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages crates-graphics)
  #:use-module (gnu packages crates-gtk)
  #:use-module (gnu packages crates-tls)
  #:use-module (gnu packages crates-vcs)
  #:use-module (gnu packages crates-web)
  #:use-module (gnu packages crates-windows)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages ibus)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages image)
  #:use-module (gnu packages jemalloc)
  #:use-module (gnu packages kde)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages libunwind)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xorg))



(define-public rust-open-5.2
  (package
    (inherit rust-open-5)
    (name "rust-open")
    (version "5.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "open" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0dvyb94cncmgxgdwyvz0ixm3gnbb0mn1rkglzq7dhfyf7yd90b4x"))))))
    ;(arguments `())))




(define-public rust-tokio-stream-0.1.15
  (package
    (inherit rust-tokio-stream-0.1)
    (name "rust-tokio-stream")
    (version "0.1.15")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "tokio-stream" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1brpbsqyg8yfmfc4y0j9zxvc8xsxjc31d48kb0g6jvpc1fgchyi6"))))))
    ;(arguments `())))




(define-public rust-clipboard-win-5
  (package
    (name "rust-clipboard-win")
    (version "5.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "clipboard-win" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "14n87fc0vzbd0wdhqzvcs1lqgafsncplzcanhpik93xhhalfgvqm"))))
    (build-system cargo-build-system)
    (arguments
     `(#:tests? #f  ; unresolved import `clipboard_win::raw`
       #:cargo-inputs (("rust-error-code" ,rust-error-code-3)
                       ("rust-windows-win" ,rust-windows-win-3))))
    (home-page "https://github.com/DoumanAsh/clipboard-win")
    (synopsis "Simple way to interact with Windows clipboard")
    (description
     "This package provides simple way to interact with Windows clipboard.")
    (license license:boost1.0)))




(define-public rust-textwrap-0.16
  (package
    (name "rust-textwrap")
    (version "0.16.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "textwrap" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1fgqn3mg9gdbjxwfxl76fg0qiq53w3mk4hdh1x40jylnz39k9m13"))))
    (build-system cargo-build-system)
    (arguments
     (list #:cargo-inputs
           `(("rust-hyphenation" ,rust-hyphenation-0.8)
             ("rust-smawk" ,rust-smawk-0.3)
             ("rust-terminal-size" ,rust-terminal-size-0.2)
             ("rust-unicode-linebreak" ,rust-unicode-linebreak-0.1)
             ("rust-unicode-width" ,rust-unicode-width-0.1))
           #:cargo-development-inputs
           `(("rust-termion" ,rust-termion-2)
             ("rust-unic-emoji-char" ,rust-unic-emoji-char-0.9)
             ("rust-version-sync" ,rust-version-sync-0.9))))
    (home-page "https://github.com/mgeisler/textwrap")
    (synopsis "Library for word wrapping, indenting, and dedenting strings")
    (description
     "Textwrap is a small library for word wrapping, indenting, and dedenting
strings.  You can use it to format strings (such as help and error messages)
for display in commandline applications.  It is designed to be efficient and
handle Unicode characters correctly.")
    (license license:expat)))




(define-public rust-slotmap-1
  (package
    (name "rust-slotmap")
    (version "1.0.7")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "slotmap" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0amqb2fn9lcy1ri0risblkcp88dl0rnfmynw7lx0nqwza77lmzyv"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs
       (("rust-serde" ,rust-serde-1)
        ("rust-version-check" ,rust-version-check-0.9))
       #:cargo-development-inputs
       (("rust-fxhash" ,rust-fxhash-0.2)
        ("rust-quickcheck" ,rust-quickcheck-0.9)
        ("rust-serde" ,rust-serde-1)
        ("rust-serde-derive" ,rust-serde-derive-1)
        ("rust-serde-json" ,rust-serde-json-1))))
    (home-page "https://github.com/orlp/slotmap")
    (synopsis "Slotmap data structure")
    (description "Slotmap data structure")
    (license license:zlib)))




(define-public rust-cov-mark-1
  (package
    (inherit rust-cov-mark-2)
    (name "rust-cov-mark")
    (version "1.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "cov-mark" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1wv75ylrai556m388a40d50fxiyacmvm6qqz6va6qf1q04z3vylz"))))))
    ;(arguments `())))





(define-public rust-pulldown-cmark-escape-0.11
  (package
    (name "rust-pulldown-cmark-escape")
    (version "0.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "pulldown-cmark-escape" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1bp13akkz52p43vh2ffpgv604l3xd9b67b4iykizidnsbpdqlz80"))))
    (build-system cargo-build-system)
    (home-page "https://github.com/pulldown-cmark/pulldown-cmark")
    (synopsis "Escape library for HTML created in the pulldown-cmark project")
    (description "This package provides an escape library for HTML created in
the pulldown-cmark project.")
    (license license:expat)))





(define-public rust-nucleo-matcher-0.2
  (package
    (name "rust-nucleo-matcher")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "nucleo-matcher" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0mxxz58acszkgxha4wy459fkcx6f8sh55d803wnid1p25x02nw0v"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-cov-mark" ,rust-cov-mark-1)
                       ("rust-memchr" ,rust-memchr-2)
                       ("rust-unicode-segmentation" ,rust-unicode-segmentation-1))
       #:cargo-development-inputs (("rust-cov-mark" ,rust-cov-mark-1))))
    (home-page "https://github.com/helix-editor/nucleo")
    (synopsis "Plug and play high performance fuzzy matcher")
    (description
     "This package provides plug and play high performance fuzzy matcher.")
    (license license:mpl2.0)))




(define-public rust-gix-submodule-0.11
  (package
    (inherit rust-gix-submodule-0.14)
    (name "rust-gix-submodule")
    (version "0.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-submodule" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1b304hkx2r2b619n3lksvj08fkd7pdxzpr923dhvc55c4jcx874j"))))
    (arguments
     `(#:cargo-inputs (("rust-bstr" ,rust-bstr-1)
                       ("rust-gix-config" ,rust-gix-config-0.37)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-pathspec" ,rust-gix-pathspec-0.7)
                       ("rust-gix-refspec" ,rust-gix-refspec-0.23)
                       ("rust-gix-url" ,rust-gix-url-0.27)
                       ("rust-thiserror" ,rust-thiserror-1))))))




(define-public rust-gix-status-0.10
  (package
    (inherit rust-gix-status-0.13)
    (name "rust-gix-status")
    (version "0.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-status" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1j5z44b80ybaxy34valibksasrd5gny52vqk9mahjf3ii7cp6hrg"))))
    (arguments
     `(#:cargo-inputs (("rust-bstr" ,rust-bstr-1)
                       ("rust-document-features" ,rust-document-features-0.2)
                       ("rust-filetime" ,rust-filetime-0.2)
                       ("rust-gix-diff" ,rust-gix-diff-0.44)
                       ("rust-gix-dir" ,rust-gix-dir-0.5)
                       ("rust-gix-features" ,rust-gix-features-0.38)
                       ("rust-gix-filter" ,rust-gix-filter-0.11)
                       ("rust-gix-fs" ,rust-gix-fs-0.11)
                       ("rust-gix-hash" ,rust-gix-hash-0.14)
                       ("rust-gix-index" ,rust-gix-index-0.33)
                       ("rust-gix-object" ,rust-gix-object-0.42)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-pathspec" ,rust-gix-pathspec-0.7)
                       ("rust-gix-worktree" ,rust-gix-worktree-0.34)
                       ("rust-thiserror" ,rust-thiserror-1))))))




(define-public rust-gix-ref-0.44
  (package
    (inherit rust-gix-ref-0.47)
    (name "rust-gix-ref")
    (version "0.44.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-ref" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0biy3y7src1wsx5prynvyg7wzyzf3ss8f6hyphpb5ijvgscs551k"))))
    (arguments
     `(#:tests? #f ;use of undeclared crate gix_testtools
       #:cargo-inputs (("rust-document-features" ,rust-document-features-0.2)
                       ("rust-gix-actor" ,rust-gix-actor-0.31)
                       ("rust-gix-date" ,rust-gix-date-0.8)
                       ("rust-gix-features" ,rust-gix-features-0.38)
                       ("rust-gix-fs" ,rust-gix-fs-0.11)
                       ("rust-gix-hash" ,rust-gix-hash-0.14)
                       ("rust-gix-lock" ,rust-gix-lock-14)
                       ("rust-gix-object" ,rust-gix-object-0.42)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-tempfile" ,rust-gix-tempfile-14)
                       ("rust-gix-utils" ,rust-gix-utils-0.1)
                       ("rust-gix-validate" ,rust-gix-validate-0.8)
                       ("rust-memmap2" ,rust-memmap2-0.9)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-winnow" ,rust-winnow-0.6))))))




(define-public rust-gix-discover-0.32
  (package
    (inherit rust-gix-discover-0.35)
    (name "rust-gix-discover")
    (version "0.32.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-discover" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1grxby9mj5c9bs305wrf70x0rsdpq25nc00csm86p9ixnscwc9zw"))))
    (arguments
     `(#:cargo-inputs (("rust-bstr" ,rust-bstr-1)
                       ("rust-dunce" ,rust-dunce-1)
                       ("rust-gix-fs" ,rust-gix-fs-0.11)
                       ("rust-gix-hash" ,rust-gix-hash-0.14)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-ref" ,rust-gix-ref-0.44)
                       ("rust-gix-sec" ,rust-gix-sec-0.10)
                       ("rust-thiserror" ,rust-thiserror-1))
       #:cargo-development-inputs (("rust-defer" ,rust-defer-0.2)
                                   ("rust-is-ci" ,rust-is-ci-1)
                                   ("rust-serial-test" ,rust-serial-test-3)
                                   ("rust-tempfile" ,rust-tempfile-3))))))




(define-public rust-gix-dir-0.5
  (package
    (inherit rust-gix-dir-0.8)
    (name "rust-gix-dir")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-dir" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0x29x6qdj4nwma01qgqadi0dwix3rnv0mlj1wnmn7gasaj69zjb0"))))
    (arguments
     `(#:tests? #f ;looking for undeclared gix-testtools
       #:cargo-inputs (("rust-bstr" ,rust-bstr-1)
                       ("rust-gix-discover" ,rust-gix-discover-0.32)
                       ("rust-gix-fs" ,rust-gix-fs-0.11)
                       ("rust-gix-ignore" ,rust-gix-ignore-0.11)
                       ("rust-gix-index" ,rust-gix-index-0.33)
                       ("rust-gix-object" ,rust-gix-object-0.42)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-pathspec" ,rust-gix-pathspec-0.7)
                       ("rust-gix-trace" ,rust-gix-trace-0.1)
                       ("rust-gix-utils" ,rust-gix-utils-0.1)
                       ("rust-gix-worktree" ,rust-gix-worktree-0.34)
                       ("rust-thiserror" ,rust-thiserror-1))
       #:cargo-development-inputs
       (("rust-pretty-assertions" ,rust-pretty-assertions-1))))))





(define-public rust-gix-config-0.37
  (package
    (inherit rust-gix-config-0.40)
    (name "rust-gix-config")
    (version "0.37.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix-config" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0h680yjj90hqch8x2bgnybx01smff2yvcrja6n7dj4byjm1gxyjk"))))
    (arguments
     `(#:cargo-inputs (("rust-bstr" ,rust-bstr-1)
                       ("rust-document-features" ,rust-document-features-0.2)
                       ("rust-gix-config-value" ,rust-gix-config-value-0.14)
                       ("rust-gix-features" ,rust-gix-features-0.38)
                       ("rust-gix-glob" ,rust-gix-glob-0.16)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-ref" ,rust-gix-ref-0.44)
                       ("rust-gix-sec" ,rust-gix-sec-0.10)
                       ("rust-memchr" ,rust-memchr-2)
                       ("rust-once-cell" ,rust-once-cell-1)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-smallvec" ,rust-smallvec-1)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-unicode-bom" ,rust-unicode-bom-2)
                       ("rust-winnow" ,rust-winnow-0.6))
       #:cargo-development-inputs (("rust-criterion" ,rust-criterion-0.5))))))




(define-public rust-hashbrown-0.14
  (package
    (inherit rust-hashbrown-0.15)
    (name "rust-hashbrown")
    (version "0.14.5")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "hashbrown" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1wa1vy1xs3mp11bn3z9dv0jricgr6a2j0zkf1g19yz3vw4il89z5"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (substitute* "Cargo.toml"
                    (("=([[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+)" _ version)
                     (string-append "^" version)))))))
    (arguments
     `(#:cargo-inputs
       (("rust-ahash" ,rust-ahash-0.8)
        ("rust-allocator-api2" ,rust-allocator-api2-0.2)
        ("rust-compiler-builtins" ,rust-compiler-builtins-0.1)
        ("rust-equivalent" ,rust-equivalent-1)
        ("rust-rayon" ,rust-rayon-1)
        ("rust-rkyv" ,rust-rkyv-0.7)
        ("rust-rustc-std-workspace-alloc" ,rust-rustc-std-workspace-alloc-1)
        ("rust-rustc-std-workspace-core" ,rust-rustc-std-workspace-core-1)
        ("rust-serde" ,rust-serde-1))
       #:cargo-development-inputs
       (("rust-bumpalo" ,rust-bumpalo-3)
        ("rust-doc-comment" ,rust-doc-comment-0.3)
        ("rust-fnv" ,rust-fnv-1)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-rand" ,rust-rand-0.8)
        ("rust-rayon" ,rust-rayon-1)
        ("rust-rkyv" ,rust-rkyv-0.7)
        ("rust-serde-test" ,rust-serde-test-1))))))




(define-public rust-gix-0.63
  (package
    (inherit rust-gix-0.66)
    (name "rust-gix")
    (version "0.63.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "gix" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "01jbkflpr570inbdjv1xgfsimqf6xfrr0yg6mlv4aypsmlc50k4q"))))
    (arguments
     `(#:cargo-inputs (("rust-async-std" ,rust-async-std-1)
                       ("rust-document-features" ,rust-document-features-0.2)
                       ("rust-gix-actor" ,rust-gix-actor-0.31)
                       ("rust-gix-archive" ,rust-gix-archive-0.13)
                       ("rust-gix-attributes" ,rust-gix-attributes-0.22)
                       ("rust-gix-command" ,rust-gix-command-0.3)
                       ("rust-gix-commitgraph" ,rust-gix-commitgraph-0.24)
                       ("rust-gix-config" ,rust-gix-config-0.37)
                       ("rust-gix-credentials" ,rust-gix-credentials-0.24)
                       ("rust-gix-date" ,rust-gix-date-0.8)
                       ("rust-gix-diff" ,rust-gix-diff-0.44)
                       ("rust-gix-dir" ,rust-gix-dir-0.5)
                       ("rust-gix-discover" ,rust-gix-discover-0.32)
                       ("rust-gix-features" ,rust-gix-features-0.38)
                       ("rust-gix-filter" ,rust-gix-filter-0.11)
                       ("rust-gix-fs" ,rust-gix-fs-0.11)
                       ("rust-gix-glob" ,rust-gix-glob-0.16)
                       ("rust-gix-hash" ,rust-gix-hash-0.14)
                       ("rust-gix-hashtable" ,rust-gix-hashtable-0.5)
                       ("rust-gix-ignore" ,rust-gix-ignore-0.11)
                       ("rust-gix-index" ,rust-gix-index-0.33)
                       ("rust-gix-lock" ,rust-gix-lock-14)
                       ("rust-gix-macros" ,rust-gix-macros-0.1)
                       ("rust-gix-mailmap" ,rust-gix-mailmap-0.23)
                       ("rust-gix-negotiate" ,rust-gix-negotiate-0.13)
                       ("rust-gix-object" ,rust-gix-object-0.42)
                       ("rust-gix-odb" ,rust-gix-odb-0.61)
                       ("rust-gix-pack" ,rust-gix-pack-0.51)
                       ("rust-gix-path" ,rust-gix-path-0.10)
                       ("rust-gix-pathspec" ,rust-gix-pathspec-0.7)
                       ("rust-gix-prompt" ,rust-gix-prompt-0.8)
                       ("rust-gix-protocol" ,rust-gix-protocol-0.45)
                       ("rust-gix-ref" ,rust-gix-ref-0.44)
                       ("rust-gix-refspec" ,rust-gix-refspec-0.23)
                       ("rust-gix-revision" ,rust-gix-revision-0.27)
                       ("rust-gix-revwalk" ,rust-gix-revwalk-0.13)
                       ("rust-gix-sec" ,rust-gix-sec-0.10)
                       ("rust-gix-status" ,rust-gix-status-0.10)
                       ("rust-gix-submodule" ,rust-gix-submodule-0.11)
                       ("rust-gix-tempfile" ,rust-gix-tempfile-14)
                       ("rust-gix-trace" ,rust-gix-trace-0.1)
                       ("rust-gix-transport" ,rust-gix-transport-0.42)
                       ("rust-gix-traverse" ,rust-gix-traverse-0.39)
                       ("rust-gix-url" ,rust-gix-url-0.27)
                       ("rust-gix-utils" ,rust-gix-utils-0.1)
                       ("rust-gix-validate" ,rust-gix-validate-0.8)
                       ("rust-gix-worktree" ,rust-gix-worktree-0.34)
                       ("rust-gix-worktree-state" ,rust-gix-worktree-state-0.11)
                       ("rust-gix-worktree-stream" ,rust-gix-worktree-stream-0.13)
                       ("rust-once-cell" ,rust-once-cell-1)
                       ("rust-parking-lot" ,rust-parking-lot-0.12)
                       ("rust-prodash" ,rust-prodash-28)
                       ("rust-regex" ,rust-regex-1)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-signal-hook" ,rust-signal-hook-0.3)
                       ("rust-smallvec" ,rust-smallvec-1)
                       ("rust-thiserror" ,rust-thiserror-1))
       #:cargo-development-inputs (("rust-anyhow" ,rust-anyhow-1)
                                   ("rust-async-std" ,rust-async-std-1)
                                   ("rust-is-ci" ,rust-is-ci-1)
                                   ("rust-pretty-assertions" ,rust-pretty-assertions-1)
                                   ("rust-serial-test" ,rust-serial-test-3)
                                   ("rust-walkdir" ,rust-walkdir-2))))))


(define-public rust-nucleo-0.2
  (package
    (name "rust-nucleo")
    (version "0.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "nucleo" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1wzx32bz4n68dcd3yw57195sz49hdhv9b75jikr5qiyfpks32lxf"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-nucleo-matcher" ,rust-nucleo-matcher-0.2)
                       ("rust-parking-lot" ,rust-parking-lot-0.12)
                       ("rust-rayon" ,rust-rayon-1))))
    (home-page "https://github.com/helix-editor/nucleo")
    (synopsis "Plug and play high performance fuzzy matcher")
    (description
     "This package provides plug and play high performance fuzzy matcher.")
    (license license:mpl2.0)))


(define-public rust-tree-sitter-0.22
  (package
    (name "rust-tree-sitter")
    (version "0.22.6")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "tree-sitter" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1jkda5n43m7cxmx2h7l20zxc74nf9v1wpm66gvgxrm5drscw8z6z"))))
    (build-system cargo-build-system)
    (arguments
     `(#:skip-build? #t
       #:cargo-inputs (("rust-cc" ,rust-cc-1)
                       ("rust-regex" ,rust-regex-1))))
    (home-page "https://tree-sitter.github.io/tree-sitter/")
    (synopsis "Rust bindings to the Tree-sitter parsing library")
    (description
     "This package provides Rust bindings to the Tree-sitter parsing library.")
    (license license:expat)))


(define-public rust-unicode-general-category-0.6
  (package
    (name "rust-unicode-general-category")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "unicode-general-category" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1rv9715c94gfl0hzy4f2a9lw7i499756bq2968vqwhr1sb0wi092"))))
    (build-system cargo-build-system)
    (home-page "https://github.com/yeslogic/unicode-general-category")
    (synopsis "Fast lookup of the Unicode General Category property for char")
    (description "This package provides Fast lookup of the Unicode General
Category property for char.")
    (license license:asl2.0)))




(define-public rust-termini-1
  (package
    (name "rust-termini")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "termini" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0n8dvbwkp2k673xqwivb01iqg5ir91zgpwhwngpcb2yrgpc43m1a"))))
    (build-system cargo-build-system)
    (arguments
     `(#:tests? #f      ; Not all files included.
       #:cargo-inputs (("rust-home" ,rust-home-0.5))))
    (home-page "https://github.com/pascalkuthe/termini")
    (synopsis "Minimal terminfo libary")
    (description "This package provides a minimal terminfo libary.")
    (license license:expat)))




(define-public rust-regex-cursor-0.1
  (package
    (name "rust-regex-cursor")
    (version "0.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "regex-cursor" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0sbi1xr9201hd5c40779gfnmlnmrb4yqs4jj07d6zbp3znsjfhxf"))))
    (build-system cargo-build-system)
    (arguments
     `(#:tests? #f      ; Not all files included.
       #:cargo-inputs (("rust-log" ,rust-log-0.4)
                       ("rust-memchr" ,rust-memchr-2)
                       ("rust-regex-automata" ,rust-regex-automata-0.4)
                       ("rust-regex-syntax" ,rust-regex-syntax-0.8)
                       ("rust-ropey" ,rust-ropey-1))
       #:cargo-development-inputs (("rust-anyhow" ,rust-anyhow-1)
                                   ("rust-proptest" ,rust-proptest-1)
                                   ("rust-regex-test" ,rust-regex-test-0.1))))
    (home-page "https://github.com/pascalkuthe/regex-cursor")
    (synopsis "Regex fork that can search discontiguous haystacks")
    (description
     "This package provides regex fork that can search discontiguous haystacks.")
    (license (list license:expat license:asl2.0))))




(define-public rust-pulldown-cmark-0.11
  (package
    (name "rust-pulldown-cmark")
    (version "0.11.3")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "pulldown-cmark" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "09a6q582pblnj8xflbx6zb29zgnwg0r6rg9wi54wdikq5k9434v7"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-bitflags" ,rust-bitflags-2)
                       ("rust-getopts" ,rust-getopts-0.2)
                       ("rust-memchr" ,rust-memchr-2)
                       ("rust-pulldown-cmark-escape" ,rust-pulldown-cmark-escape-0.11)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-unicase" ,rust-unicase-2))
       #:cargo-development-inputs (("rust-bincode" ,rust-bincode-1)
                                   ("rust-lazy-static" ,rust-lazy-static-1)
                                   ("rust-regex" ,rust-regex-1)
                                   ("rust-serde-json" ,rust-serde-json-1))))
    (home-page "https://github.com/pulldown-cmark/pulldown-cmark")
    (synopsis "Pull parser for CommonMark")
    (description "This package provides a pull parser for CommonMark.")
    (license license:expat)))




(define-public helix
  (package
    (name "helix")
    (version "24.07")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/helix-editor/helix")
             (commit version)))
       (modules '((guix build utils)))
       (snippet '(begin
                   (delete-file-recursively "Cargo.lock")))
       (file-name (git-file-name "helix" version))
       (sha256
        (base32 "1f0l65z1cy8m9x79p5y5kwk1psv0ppfz9lwylggm71q0lj127awl"))))
    (build-system cargo-build-system)
    (arguments
     `(#:install-source? #f
       #:phases ,#~(modify-phases %standard-phases
                     (add-after 'unpack 'disable-grammar-build
                       (lambda _
                         (setenv "HELIX_DISABLE_AUTO_GRAMMAR_BUILD" "1")))
                     (replace 'install
                       (lambda _
                         (let* ((bin (string-append #$output "/bin"))
                                (hx (string-append bin "/hx"))
                                (share (string-append #$output
                                                      "/usr/share/helix"))
                                (runtime (string-append share "/runtime"))
                                (applications (string-append #$output
                                               "/share/applications")))
                           (install-file "target/release/hx" bin)
                           (install-file "contrib/Helix.desktop" applications)
                           (copy-recursively "runtime" runtime)
                           (wrap-program hx
                             `("HELIX_RUNTIME" prefix
                               (,runtime)))))))
       #:cargo-inputs (("rust-ahash" ,rust-ahash-0.8)
                       ("rust-anyhow" ,rust-anyhow-1)
                       ("rust-arc-swap" ,rust-arc-swap-1)
                       ("rust-bitflags" ,rust-bitflags-2)
                       ("rust-cassowary" ,rust-cassowary-0.3)
                       ("rust-cc" ,rust-cc-1)
                       ("rust-chardetng" ,rust-chardetng-0.1)
                       ("rust-chrono" ,rust-chrono-0.4)
                       ("rust-clipboard-win" ,rust-clipboard-win-5)
                       ("rust-content-inspector" ,rust-content-inspector-0.2)
                       ("rust-crossterm" ,rust-crossterm-0.27)
                       ("rust-dunce" ,rust-dunce-1)
                       ("rust-encoding-rs" ,rust-encoding-rs-0.8)
                       ("rust-etcetera" ,rust-etcetera-0.8)
                       ("rust-fern" ,rust-fern-0.6)
                       ("rust-futures-executor" ,rust-futures-executor-0.3)
                       ("rust-futures-util" ,rust-futures-util-0.3)
                       ("rust-gix" ,rust-gix-0.63)
                       ("rust-globset" ,rust-globset-0.4)
                       ("rust-grep-regex" ,rust-grep-regex-0.1)
                       ("rust-grep-searcher" ,rust-grep-searcher-0.1)
                       ("rust-hashbrown" ,rust-hashbrown-0.14)
                       ("rust-ignore" ,rust-ignore-0.4)
                       ("rust-imara-diff" ,rust-imara-diff-0.1)
                       ("rust-indoc" ,rust-indoc-2)
                       ("rust-libc" ,rust-libc-0.2)
                       ("rust-libloading" ,rust-libloading-0.8)
                       ("rust-log" ,rust-log-0.4)
                       ("rust-lsp-types" ,rust-lsp-types-0.95)
                       ("rust-nucleo" ,rust-nucleo-0.2)
                       ("rust-once-cell" ,rust-once-cell-1)
                       ("rust-open" ,rust-open-5.2)
                       ("rust-parking-lot" ,rust-parking-lot-0.12)
                       ("rust-pulldown-cmark" ,rust-pulldown-cmark-0.11)
                       ("rust-quickcheck" ,rust-quickcheck-1)
                       ("rust-regex" ,rust-regex-1)
                       ("rust-regex-cursor" ,rust-regex-cursor-0.1)
                       ("rust-ropey" ,rust-ropey-1)
                       ("rust-rustix" ,rust-rustix-0.38)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-serde-json" ,rust-serde-json-1)
                       ("rust-signal-hook" ,rust-signal-hook-0.3)
                       ("rust-signal-hook-tokio" ,rust-signal-hook-tokio-0.3)
                       ("rust-slotmap" ,rust-slotmap-1)
                       ("rust-smallvec" ,rust-smallvec-1)
                       ("rust-smartstring" ,rust-smartstring-1)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-termini" ,rust-termini-1)
                       ("rust-textwrap" ,rust-textwrap-0.16)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-threadpool" ,rust-threadpool-1)
                       ("rust-tokio" ,rust-tokio-1)
                       ("rust-tokio-stream" ,rust-tokio-stream-0.1.15)
                       ("rust-toml" ,rust-toml-0.8)
                       ("rust-tree-sitter" ,rust-tree-sitter-0.22)
                       ("rust-unicode-general-category" ,rust-unicode-general-category-0.6)
                       ("rust-unicode-segmentation" ,rust-unicode-segmentation-1)
                       ("rust-unicode-width" ,rust-unicode-width-0.1)
                       ("rust-url" ,rust-url-2)
                       ("rust-which" ,rust-which-6)
                       ("rust-windows-sys" ,rust-windows-sys-0.52))))
    (inputs (list bash-minimal))
    (native-inputs (list git))
    (home-page "https://helix-editor.com/")
    (synopsis "Post-modern modal text editor")
    (description "A Kakoune / Neovim inspired editor, written in Rust.")
    (license (list license:mpl2.0))))

