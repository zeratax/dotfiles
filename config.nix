{ 
  allowUnfree = true; 
  packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
      repoOverrides = {
        zeratax = import ~/git/nur-packages;
        ## remote locations are also possible:
        # mic92 = import (builtins.fetchTarball "https://github.com/your-user/nur-packages/archive/master.tar.gz");
      };
    };
  };
}
