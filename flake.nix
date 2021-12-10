{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      defaultScope = with pkgs; {
        inherit (qt5) qtbase wrapQtAppsHook;
        inherit (xorg) libX11 libXrender libXtst;
        gtk = gtk3;
      };

      nixPkgs =  rec {
        callPackage = pkgs.newScope (defaultScope // nixPkgs);
        omnetpp = callPackage ./. { };
        keetchi = callPackage ./keetchi.nix { };
        inet = callPackage ./inet.nix { };
        ops = callPackage ./ops.nix { };
        osgearth = callPackage ./osgearth.nix { gdal = pkgs.gdal_2; };
      };
    in {
      packages.${system} = nixPkgs;
      defaultPackage.${system} = nixPkgs.omnetpp;
      defaultApp.${system} = nixPkgs.omnetpp;
      legacyPackages.${system} = nixPkgs;
    };
}
