let inherit (import <nixpkgs> {})
      stdenv clang bision flex perl python python3 tcl tk libxml2 zlib jre
      doxygen graphviz libwebkitgtk qt5 libsForQt5 openmpi libpcap;
in
{ stdenv ? stdenv
, src ? ./omnetpp
, clang ? clang
, bision ? bision
, flex ? flex
, perl ? perl
, python ? python
, python3 ? python3
, qt5 ? qt5
, libsForQt5 ? libsForQt5
, tcl ? tcl
, tk ? tk
, jre ? jre
, libxml2 ? libxml2
, graphviz ? graphviz
, libwebkitgtk ? libwebkitgtk
, enable3dVisualization ? false
, openscenegraph ? openscenegraph
, enableParallel ? true
, openmpi ? openmpi
, enablePCAP ? false
, libpcap ? libpcap
}:

assert enable3dVisualization -> openscenegraph != null;
assert enableParallel -> openmpi != null;
assert enablePCAP -> libpcap != null;

stdenv.mkDerivation {
  name = "omnetpp";
  src = src;

  nativeBuildInputs = [ clang doxygen ];
  buildInputs = [ bision flex perl python python3 qt5.qtbase tcl tk libxml2
                  graphviz libwebkitgtk zlib  jre ]
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
