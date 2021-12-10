let
  nixpkgs = import <nixpkgs> {};
in { pkgs ? nixpkgs }:

let
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

in nixPkgs
