let pkgs = import <nixpkgs> {};
in
{ stdenv                ? pkgs.stdenv
, src                   ? ./omnetpp
, clang                 ? pkgs.clang
, bison                 ? pkgs.bison
, flex                  ? pkgs.flex
, perl                  ? pkgs.perl
, python                ? pkgs.python
, python3               ? pkgs.python3
, qt5                   ? pkgs.qt5
, libsForQt5            ? pkgs.libsForQt5
, tcl                   ? pkgs.tcl
, tk                    ? pkgs.tk
, jre                   ? pkgs.jre
, libxml2               ? pkgs.libxml2
, graphviz              ? pkgs.graphviz
, webkitgtk             ? pkgs.webkitgtk
, enable3dVisualization ? false
, openscenegraph        ? pkgs.openscenegraph
, enableParallel        ? true
, openmpi               ? pkgs.openmpi
, enablePCAP            ? false
, libpcap               ? pkgs.libpcap
, doxygen               ? pkgs.doxygen
, zlib                  ? pkgs.zlib
}:

assert enable3dVisualization -> openscenegraph != null;
assert enableParallel -> openmpi != null;
assert enablePCAP -> libpcap != null;

stdenv.mkDerivation {
  name = "omnetpp";
  src = src;

  nativeBuildInputs = [ clang doxygen ];
  buildInputs = [ bison flex perl python python3 qt5.qtbase tcl tk libxml2
                  graphviz webkitgtk zlib  jre ]
                ++ (if enable3dVisualization
                    then [ openscenegraph ]
                    else [ ])
                ++ (if enableParallel
                    then [ openmpi ]
                    else [ ])
                ++ (if enablePCAP
                    then [ libpcap ]
                    else [ ]);
  outputs = [ "out" "doc" ];
  configureFlags = [] ++
                   (if ! enable3dVisualization
                    then [ "--WITH_OSGEARTH=no"
                           "--WITH_OSG=no"
                         ]
                    else []) ++
                   (if ! enableParallel
                    then [ "--WITH_PARSIM=no" ]
                    else []);
}
