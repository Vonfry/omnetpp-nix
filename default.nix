let pkgs = import <nixpkgs> {};
    python3with = pkgs.python3.withPackages
      (pkgs: with pkgs; [ numpy scipy pandas ipython ]);
in
{ stdenv                ? pkgs.stdenv
, callPackage           ? pkgs.qt5.callPackage
, lib                   ? pkgs.lib
, fetchurl              ? pkgs.fetchurl
, gawk                  ? pkgs.gawk
, file                  ? pkgs.file
, which                 ? pkgs.which
, bison                 ? pkgs.bison
, flex                  ? pkgs.flex
, perl                  ? pkgs.perl
, python3               ? python3with
, qtbase                ? pkgs.qt5.qtbase
, wrapQtAppsHook        ? pkgs.qt5.wrapQtAppsHook
, libsForQt5            ? pkgs.libsForQt5
, jre                   ? pkgs.jre
, libxml2               ? pkgs.libxml2
, graphviz              ? pkgs.graphviz
, webkitgtk             ? pkgs.webkitgtk
, withIDE               ? true
, withNEDDocGen         ? true
, with3dVisualization   ? false
, openscenegraph        ? pkgs.openscenegraph
, osgearth              ? callPackage ./osgearth.nix { gdal = pkgs.gdal_2; }
, withParallel          ? true
, openmpi               ? pkgs.openmpi
, withPCAP              ? true
, libpcap               ? pkgs.libpcap
, doxygen               ? pkgs.doxygen
, zlib                  ? pkgs.zlib
, nemiver               ? pkgs.nemiver
, akaroa                ? null # not free
, autoPatchelfHook      ? pkgs.autoPatchelfHook
}:

assert withIDE -> ! builtins.any isNull [ qtbase jre ];
assert (withIDE && withNEDDocGen) -> ! builtins.any isNull [ doxygen graphviz ];
assert with3dVisualization -> ! builtins.any isNull [ osgearth openscenegraph ];
assert withParallel -> ! isNull openmpi;
assert withPCAP -> ! isNull libpcap;

let
  qtbaseDevDirsSet = builtins.readDir (qtbase.dev + /include);
  qtbaseDevDirs = builtins.filter
                    (n: (builtins.getAttr n qtbaseDevDirsSet) == "directory")
                        (builtins.attrNames qtbaseDevDirsSet);
  qtbaseCFlags = builtins.foldl'
                  (l: x: l + " -isystem " + (qtbase.dev + /include) + "/" + x )
                  "" qtbaseDevDirs;
  libxml2CFlags = " -isystem ${libxml2.dev}/include/libxml2 ";
in
stdenv.mkDerivation rec {
  pname = "omnetpp";
  version = "5.6.2";

  src = fetchurl {
    url = "https://github.com/omnetpp/omnetpp/releases/download/omnetpp-5.6.2/omnetpp-5.6.2-src-linux.tgz";
    sha256 = "0r8vfy90xah7wp49kdlz0a5x0b6nxy2ny9w45cbxr1l4759xdc4p";
  };

  outputs = [ "out" ];

  propagatedNativeBuildInputs = [ gawk which perl bison flex file ];

  nativeBuildInputs = [ ]
                   ++ lib.optional withIDE [ wrapQtAppsHook autoPatchelfHook ];

  buildInputs = [ python3 nemiver akaroa zlib libxml2]
             ++ lib.optionals withIDE [ qtbase jre ]
             ++ lib.optionals (withIDE && withNEDDocGen) [graphviz doxygen  webkitgtk ]
             ++ lib.optionals with3dVisualization [ osgearth openscenegraph ]
             ++ lib.optional withParallel openmpi
             ++ lib.optional withPCAP libpcap;

  # dontWrapQtApps = true;
  # qtWrappersArgs = [ ];

  NIX_CFLAGS_COMPILE = qtbaseCFlags + libxml2CFlags;

  patches = [ ./patch.setenv
              ./patch.HOME
              ./patch.omnetpp
            ];

  configureFlags = [ ]
                   ++ lib.optionals (!withIDE) [ "WITH_QTENV=no"
                                                  "WITH_TKENV=no"
                                                ]
                   ++ lib.optionals (!(withIDE && with3dVisualization))
                     [ "WITH_OSG=no" "WITH_OSGEARTH=no"]
                   ++ lib.optional (!withParallel) "WITH_PARSIM=no";

  preConfigure = ''
    . setenv
    # use patch instead, becasue of configure script has a problem with space
    # split between ~isystem~ and ~path~.
    export AR="ar cr"
    '';

  # Because omnetpp configure and makefile don't have install flag. In common,
  # all things run under omnetpp source directory. So I copy some file into out
  # directory by myself, but I don't know whether it can work or not.
  installPhase = ''
    runHook preInstall

    mkdir -p ${placeholder "out"}

    cp -r . ${placeholder "out"}

    runHook postInstall
    '';

  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} -type f); do
        rpath=$(patchelf --print-rpath $bin  \
                | sed -E "s,:\\.:,:,g"                                                             \
                | sed -E "s,:?$build_pwd/lib:?,:${placeholder "out"}/lib:,g"                       \
                | sed -E "s,:?$build_pwd/lib64:?,:,g"                                              \
                | sed -E "s,:?$build_pwd/samples,:${placeholder "out"}/share/omnetpp/samples,g"    \
                | sed -E "s,:?${placeholder "out"}/lib:?,:${placeholder "out"}/lib:,g"             \
                | sed -E "s,:+,:,g"                                                                \
                | sed -E "s,^:,,"                                                                  \
                | sed -E "s,:$,,"                                                                  \
               || echo )
        if [ -n "$rpath" ]; then
          patchelf --set-rpath "$rpath" $bin
        fi
      done
    )
    '';

  postFixup = ''
    autoPatchelfFile ${placeholder "out"}/ide/omnetpp
    '';

  meta = with stdenv.lib; {
    homepage= "https://omnetpp.org";
    description = "OMNeT++ is an extensible, modular, component-based C++ simulation library and framework, primarily for building network simulators.";
    license = licenses.unlicense;
    platforms = platforms.unix;
  };
}
