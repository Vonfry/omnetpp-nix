let pkgs = import <nixpkgs> {};
in
{ stdenv                ? pkgs.stdenv
, gawk                  ? pkgs.gawk
, which                 ? pkgs.which
, bison                 ? pkgs.bison
, flex                  ? pkgs.flex
, perl                  ? pkgs.perl
, python                ? pkgs.python
, python3               ? pkgs.python3
, qtbase                ? pkgs.qt5.qtbase
, libsForQt5            ? pkgs.libsForQt5
, tcl                   ? pkgs.tcl
, tk                    ? pkgs.tk
, jre                   ? pkgs.jre
, libxml2               ? pkgs.libxml2
, graphviz              ? pkgs.graphviz
, webkitgtk             ? pkgs.webkitgtk
, enable3dVisualization ? false
, openscenegraph        ? pkgs.openscenegraph
, enableParallel        ? false
, openmpi               ? pkgs.openmpi
, enablePCAP            ? false
, libpcap               ? pkgs.libpcap
, doxygen               ? pkgs.doxygen
, inkscape              ? pkgs.inkscape
, zlib                  ? pkgs.zlib
, nemiver               ? pkgs.nemiver
, akaroa                ? null
}:

assert enable3dVisualization -> openscenegraph != null;
assert enableParallel -> openmpi != null && akaroa != null;
assert enablePCAP -> libpcap != null;

stdenv.mkDerivation rec {
  src = ./omnetpp;
  name = builtins.replaceStrings [ "\n" ]  [ "" ]
          (builtins.readFile (src + /Version));

  outputs = [ "out" "doc" "dev" ];

  nativeBuildInputs = [ gawk which doxygen qtbase ];
  buildInputs = [ bison flex perl python python3 tcl libxml2 graphviz perl
                  qtbase tk inkscape webkitgtk zlib jre nemiver
                ]
                ++ (if enable3dVisualization
                    then [ openscenegraph ]
                    else [ ])
                ++ (if enableParallel
                    then [ openmpi akaroa ]
                    else [ ])
                ++ (if enablePCAP
                    then [ libpcap ]
                    else [ ]);

  patches = [ ./patch.configure ./patch.setenv ./patch.HOME ];
  configureFlags = [ ]
                   ++ (if ! enable3dVisualization
                       then [ "WITH_OSG=no" "WITH_OSGEARTH=no" ]
                       else [])
                   ++ (if ! enableParallel
                       then [ "WITH_PARSIM=no" ]
                       else []);
  preConfigure = ''
    cp configure.user.dist configure.user
    . setenv
    export QT_CORE_INCLUDE=" -isystem ${qtbase.dev}/include/QtCore "
    '';
}
