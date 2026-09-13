;; Build with: guix home build /home/liz/guix/home.scm
;; Apply as liz: guix home reconfigure /home/liz/guix/home.scm
(use-modules (gnu home)
             (gnu services)
             (gnu home services shells)
             ((gnu packages shellutils) #:select (starship))
             (guix gexp))

(home-environment
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
