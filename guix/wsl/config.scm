;; Requires Guix 1.5.0 or newer for operating-system-for-image's WSL fix.
;; Build with: guix system image --image-type=wsl2 wsl-liz.scm
;; Reconfigure inside WSL with:
;; sudo guix system reconfigure --skip-checks --no-bootloader --no-kexec /home/liz/guix/config.scm
(use-modules (gnu)
             (guix gexp)
             ((gnu packages) #:select (specifications->packages
                                      %package-module-path))
             ((gnu packages shells) #:select (fish))
             ((gnu system image) #:select (operating-system-for-image))
             (gnu system images wsl2))

;; Use the working tree directly so local edits are available immediately.
(add-to-load-path "/home/liz/cchanl")
(%package-module-path
 (cons '("/home/liz/cchanl" . "ch0r0ng/packages")
       (%package-module-path)))

;; Preserve the official image's generated file-system metadata so this
;; configuration also works with `guix system reconfigure`.
(define base-os
  (operating-system-for-image wsl2-image))

(operating-system
 (inherit base-os)
 (packages
  (append
   (specifications->packages
    '(;; Editing, repositories, and terminal sessions.
      "git" "neovim" "github-cli" "openssh" "tmux"
      ;; Interactive shell and prompt.
      "fish" "starship"
      ;; Codex from the local cchanl, including its runtime helpers.
      "codex@0.154.0"
      "bubblewrap"
      ;; Searching, inspecting files, and working with APIs.
      "ripgrep" "fd" "jq" "curl" "file" "tree"
      ;; Common scripting runtimes and shell checks.
      "python-wrapper" "python-pip" "node" "shellcheck"
      ;; C/C++ builds and native Python/Node.js dependencies.
      "gcc-toolchain@14" "make" "pkg-config" "cmake" "ninja"
      ;; Archive formats not already provided by the base system.
      "zip" "unzip"))
   (operating-system-packages base-os)))
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
       (operating-system-users base-os))))
