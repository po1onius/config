(use-modules (gnu home)
             (gnu services)
             ((gnu packages) #:select (specifications->packages))
             (gnu home services shells)
             ((gnu packages shellutils) #:select (starship))
             (guix gexp))

(home-environment
 (packages
  (specifications->packages
   '(;; Editing, repositories, and terminal sessions.
     "git" "neovim" "github-cli" "openssh" "tmux"
     ;; Interactive shell and prompt.
     "fish" "starship"
     ;; Codex from the configured channel, including its runtime helpers.
     "codex-bin@0.154.0"
     "bubblewrap"
     ;; Searching, inspecting files, and working with APIs.
     "ripgrep" "fd" "jq" "curl" "file" "tree"
     ;; Python project management, JavaScript runtime, and shell checks.
     "uv" "node" "shellcheck"
     ;; C/C++ builds and native Python/Node.js dependencies.
     "gcc-toolchain@14" "make" "pkg-config" "cmake" "ninja"
     ;; Archive formats not already provided by the base system.
     "zip" "unzip")))
 (services
  (list
   (service home-fish-service-type
            (home-fish-configuration
             (config
              (list
               (mixed-text-file
                "fish-starship.fish"
                "if status is-interactive\n"
                "    " (file-append starship "/bin/starship")
                " init fish | source\n"
                "end\n"))))))))
