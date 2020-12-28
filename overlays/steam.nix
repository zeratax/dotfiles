# self: super:

# {
#   steam = super.steam.overrideAttrs ( old: rec {
#     version = "1.0.0.64";
#     src =  self.fetchurl rec {
#       url = "http://repo.steampowered.com/steam/pool/steam/s/steam/steam_${version}.tar.gz";
#       sha256 = "19kwgng9n1n21b53daaz1kxrvlw6smyzgshcimlfp144h75rvlvj";
#     };
#   });
# }

