let pkgs = import <nixpkgs> {};
    python3with = pkgs.python3.withPackages
      (pkgs: with pkgs; [ numpy scipy pandas ipython ]);
in
{ stdenv                ? pkgs.stdenv
, callPackage           ? pkgs.callPackage
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
, libxml2               ? pkgs.libxml2
, zlib                  ? pkgs.zlib
, nemiver               ? pkgs.nemiver
, withIDE               ? true
, jdk                   ? pkgs.jdk12
, makeWrapper           ? pkgs.makeWrapper
, glib                  ? pkgs.glib
, cairo                 ? pkgs.cairo
, gsettings-desktop-schemas ? pkgs.gsettings-desktop-schemas
, gtk                   ? pkgs.gtk3
, swt                   ? pkgs.swt
, fontconfig            ? pkgs.fontconfig
, freetype              ? pkgs.freetype
, libX11                ? pkgs.xorg.libX11
, libXrender            ? pkgs.xorg.libXrender
, libXtst               ? pkgs.xorg.libXtst
, webkitgtk             ? pkgs.webkitgtk
, libsoup               ? pkgs.libsoup
, atk                   ? pkgs.atk
, gdk-pixbuf            ? pkgs.gdk-pixbuf
, pango                 ? pkgs.pango
, libglvnd              ? pkgs.libglvnd
, libsecret             ? pkgs.libsecret
, withNEDDocGen         ? true
, graphviz              ? pkgs.graphviz
, doxygen               ? pkgs.doxygen
, with3dVisualization   ? false
, openscenegraph        ? pkgs.openscenegraph
, osgearth              ? callPackage ./osgearth.nix { gdal = pkgs.gdal_2; }
, withParallel          ? true
, openmpi               ? pkgs.openmpi
, withPCAP              ? true
, libpcap               ? pkgs.libpcap
, akaroa                ? null # not free
}:

assert withIDE -> ! builtins.any isNull [ jdk ];
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

  propagatedNativeBuildInputs = [ gawk which perl file wrapQtAppsHook ];

  nativeBuildInputs = lib.optional withIDE [ makeWrapper ];

  buildInputs = [ python3 nemiver akaroa zlib libxml2  qtbase bison flex ]
             ++ lib.optionals withIDE [ jdk  webkitgtk gtk
                                        fontconfig freetype libX11 libXrender
                                        glib gsettings-desktop-schemas swt cairo
                                        libsoup atk gdk-pixbuf pango libsecret
                                        libglvnd
                                      ] # some of them has been contained in propagatedbuildinputs
             ++ lib.optionals (withIDE && withNEDDocGen) [ graphviz doxygen ]
             ++ lib.optionals with3dVisualization [ osgearth openscenegraph ]
             ++ lib.optional withParallel openmpi
             ++ lib.optional withPCAP libpcap;

  # dontWrapQtApps = true;
  # qtWrappersArgs = [ ];

  NIX_CFLAGS_COMPILE = qtbaseCFlags + libxml2CFlags;

  patches = [ ./patch.HOME
              ./patch.omnetpp
            ];

  configureFlags = [ "WITH_TKENV=no" ]
                   ++ lib.optionals (!with3dVisualization) [ "WITH_OSG=no"
                                                             "WITH_OSGEARTH=no"
                                                           ]
                   ++ lib.optional (!withParallel) "WITH_PARSIM=no";

  preConfigure = ''
    omnetpp_root=`pwd`
    export PATH=$omnetpp_root/bin:$PATH
    export HOSTNAME
    export HOST
    export QT_SELECT=5 # on systems with qtchooser, switch to Qt5
    # use patch instead, becasue of configure script has a problem with space
    # split between ~isystem~ and ~path~.
    export AR="ar cr"
    '';

  enableParallelBuilding = true;

  # Because omnetpp configure and makefile don't have install flag. In common,
  # all things run under omnetpp source directory. So I copy some file into out
  # directory by myself, but I don't know whether it can work or not.
  installPhase = ''
    runHook preInstall

    mkdir -p ${placeholder "out"}

    cp -r lib ${placeholder "out"}/lib
    cp -r bin ${placeholder "out"}/bin
    cp -r include ${placeholder "out"}/include
    cp -r ide ${placeholder "out"}/ide
    mkdir ${placeholder "out"}/share
    cp -r samples ${placeholder "out"}/share/samples
    cp -r doc ${placeholder "out"}/share/doc

    runHook postInstall
    '';

  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} -type f -executable); do
        rpath=$(patchelf --print-rpath $bin  \
                | sed -E "s,:?$build_pwd/lib:?,:${placeholder "out"}/lib:,g"                       \
                | sed -E "s,:?$build_pwd/lib64:?,:${placeholder "out"}/lib64:,g"                   \
                | sed -E "s,:?$build_pwd/samples,:${placeholder "out"}/samples,g"                  \
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

  dontStrip = true;

  postFixup = ''
    ( # wrap ide
      cd ${placeholder "out"}/ide
      patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux*.so.2 ./omnetpp
      wrapProgram ${placeholder "out"}/ide/omnetpp \
        --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
        --prefix LD_LIBRARY_PATH : ${jdk}/lib/openjdk/lib/amd64 \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (lib.flatten
                                      [ freetype fontconfig libX11 libXrender
                                        zlib glib gtk libXtst webkitgtk swt
                                        cairo libsoup atk gdk-pixbuf pango
                                        libglvnd libsecret
                                      ])} \
        --prefix PATH : ${lib.makeBinPath [ jdk ]}
    )
    for bin in $(find ${placeholder "out"}/share/samples -type f -executable); do
      wrapQtApp $bin
    done
    '';

  meta = with lib; {
    homepage= "https://omnetpp.org";
    description = "OMNeT++ is an extensible, modular, component-based C++ simulation library and framework, primarily for building network simulators.";
    license = licenses.unlicense;
    platforms = platforms.unix;
  };
}
