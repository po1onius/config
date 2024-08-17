k:
let
  localfile = {
    clash = "replace your config path here";
    # like ~/.config/clash/config.yaml
  };
in
  localfile."${k}"
