let pkgs = import <nixpkgs> {};
    python3with = pkgs.python3.withPackages
      (pkgs: with pkgs; [ numpy scipy pandas ipython ]);
in
{ stdenv                ? pkgs.stdenv
, gawk                  ? pkgs.gawk
, file                  ? pkgs.file
, which                 ? pkgs.which
, bison                 ? pkgs.bison
, flex                  ? pkgs.flex
, perl                  ? pkgs.perl
, python                ? pkgs.python
, python3               ? python3with
, qtbase                ? pkgs.qt5.qtbase
, libsForQt5            ? pkgs.libsForQt5
, tcl                   ? pkgs.tcl
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

let

  qtbaseDevDirsSet = builtins.readDir (qtbase.dev + /include);
  qtbaseDevDirs = builtins.filter
                    (n: (builtins.getAttr n qtbaseDevDirsSet) == "directory")
                    (builtins.attrNames qtbaseDevDirsSet);
  qtbaseCFlags = builtins.foldl'
                  (l: x: l + " -isystem " + (qtbase.dev + /include) + "/" + x )
                  "" qtbaseDevDirs;
in
stdenv.mkDerivation rec {
  src = ./omnetpp;
  name = builtins.replaceStrings [ "\n" ]  [ "" ]
          (builtins.readFile (src + /Version));

  outputs = [ "out" ];

  propagatedNativeBuildInputs = [ gawk which doxygen graphviz perl bison flex
                                  file ];
  buildInputs = [ python python3 tcl libxml2 qtbase inkscape webkitgtk zlib
                  jre nemiver
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

  NIX_CFLAGS_COMPILE = qtbaseCFlags;

  patches = [ ./patch.setenv
              ./patch.HOME
              ./patch.configure
            ];
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
    # export CFLAGS=$NIX_CFLAGS_COMPILE
    # use patch instead, becasue of configure script has a problem with space
    # split between ~isystem~ and ~path~.
    export AR="$AR cr"
    '';

  # Because omnetpp configure and makefile don't have install flag. In common,
  # all things run under omnetpp source directory. So I copy some file into out
  # directory by myself, but I don't know whether it can work or not.
  installPhase = ''
    runHook preInstall

    mkdir -p ${placeholder "out"}
    mkdir -p ${placeholder "out"}
    mkdir -p ${placeholder "out"}

    cp -r bin ${placeholder "out"}
    cp -r out ${placeholder "out"}
    cp -r include ${placeholder "out"}
    cp -r lib ${placeholder "out"}
    cp -r doc ${placeholder "out"}
    mkdir -p ${placeholder "out"}/share/omnetpp
    cp -r samples ${placeholder "out"}/share/omnetpp

    runHook postInstall
    '';
  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} ${placeholder "doc"} ${placeholder "dev"} -type f); do
        set -x
        patchelf --print-rpath $bin || echo
        (patchelf --print-rpath $bin > /dev/null 2>&1) && patchelf --set-rpath \
          $(patchelf --print-rpath $bin  \
           | sed -E "s,:?$build_pwd/lib:?,:${placeholder "out"}/lib:,g"                       \
           | sed -E "s,:?$build_pwd/samples:?,:${placeholder "out"}/share/omnetpp/samples:,g" \
           | sed -E "s,:+,:,g"                                                                \
           | sed -E "s,^:,,"                                                                  \
           | sed -E "s,:$,,"                                                                  \
           ) $bin
        set +x
      done
    )
    '';
}
