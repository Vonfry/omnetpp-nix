{ stdenv, callPackage, lib, fetchurl, gawk, file, which, bison, flex, perl,
  python3, qtbase, wrapQtAppsHook, libxml2, zlib, nemiver, withIDE ? true, jdk,
  makeWrapper, glib, cairo, gsettings-desktop-schemas, gtk, swt, fontconfig,
  freetype, libX11, libXrender, libXtst, webkitgtk, libsoup, atk, gdk-pixbuf,
  pango, libglvnd, libsecret, withNEDDocGen ? true, graphviz, doxygen,
  with3dVisualization ? false, openscenegraph, osgearth, withParallel ? true,
  openmpi, withPCAP ? true, libpcap,
  akaroa ? null # not free
}:

assert withIDE -> ! builtins.any isNull [ jdk ];
assert (withIDE && withNEDDocGen) -> ! builtins.any isNull [ doxygen graphviz ];
assert with3dVisualization -> ! builtins.any isNull [ osgearth openscenegraph ];
assert withParallel -> ! isNull openmpi;
assert withPCAP -> ! isNull libpcap;

with lib;
let
  qtbaseDevDirs =
    mapAttrsToList (n: _: n)
                   (filterAttrs (_: v: v == "directory")
                                (builtins.readDir (qtbase.dev + /include)));
  qtbaseCFlags =
    concatMapStringsSep " "
                        (x: "-isystem ${qtbase.dev + /include}/${x}")
                        qtbaseDevDirs;
  libxml2CFlags = "-isystem ${libxml2.dev}/include/libxml2";
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

  nativeBuildInputs = optional withIDE [ makeWrapper ];

  buildInputs = [ python3 nemiver akaroa zlib libxml2  qtbase bison flex ]
             ++ optionals withIDE [ jdk  webkitgtk gtk
                                        fontconfig freetype libX11 libXrender
                                        glib gsettings-desktop-schemas swt cairo
                                        libsoup atk gdk-pixbuf pango libsecret
                                        libglvnd
                                      ] # some of them has been contained in propagatedbuildinputs
             ++ optionals (withIDE && withNEDDocGen) [ graphviz doxygen ]
             ++ optionals with3dVisualization [ osgearth openscenegraph ]
             ++ optional withParallel openmpi
             ++ optional withPCAP libpcap;

  # dontWrapQtApps = true;
  # qtWrappersArgs = [ ];

  NIX_CFLAGS_COMPILE = concatStringsSep " " [ qtbaseCFlags libxml2CFlags ];

  patches = [ ./patch.HOME
              ./patch.omnetpp
            ];

  configureFlags = [ "WITH_TKENV=no" ]
                   ++ optionals (!with3dVisualization) [ "WITH_OSG=no"
                                                             "WITH_OSGEARTH=no"
                                                           ]
                   ++ optional (!withParallel) "WITH_PARSIM=no";

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

    installFiles=(lib bin include ide)
    for f in ''${installFiles[@]}; do
      cp -r $f ${placeholder "out"}
    done

    mkdir -p ${placeholder "out"}/share
    shareFiles=(Makefile.inc samples doc)
    for f in ''${shareFiles[@]}; do
      cp -r $f ${placeholder "out"}/share
    done

    runHook postInstall
    '';

  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} -type f -executable); do
        rpath=$(patchelf --print-rpath $bin  \
                | sed -E "s,$build_pwd,${placeholder "out"}:,g" \
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
        --prefix LD_LIBRARY_PATH : ${makeLibraryPath (flatten
                                      [ freetype fontconfig libX11 libXrender
                                        zlib glib gtk libXtst webkitgtk swt
                                        cairo libsoup atk gdk-pixbuf pango
                                        libglvnd libsecret
                                      ])} \
        --prefix PATH : ${makeBinPath [ jdk ]}
    )
    for bin in $(find ${placeholder "out"}/share/samples -type f -executable); do
      wrapQtApp $bin
    done

    (
        cd ${placeholder "out"}/bin
        substituteInPlace opp_configfilepath \
          --replace ".." "../share"
    )
    '';

  meta = with lib; {
    homepage= "https://omnetpp.org";
    description = "OMNeT++ is an extensible, modular, component-based C++ simulation library and framework, primarily for building network simulators.";
    license = licenses.unlicense;
    platforms = platforms.unix;
  };
}
