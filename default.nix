let pkgs = import <nixpkgs> {};
    python3with = pkgs.python3.withPackages
      (pkgs: with pkgs; [ numpy scipy pandas ipython ]);
in
{ stdenv                ? pkgs.stdenv
, lib                   ? pkgs.lib
, fetchFromGithub       ? pkgs.fetchFromGithub
, gawk                  ? pkgs.gawk
, file                  ? pkgs.file
, which                 ? pkgs.which
, bison                 ? pkgs.bison
, flex                  ? pkgs.flex
, perl                  ? pkgs.perl
, python3               ? python3with
, qtbase                ? pkgs.qt5.qtbase
, wrapQtAppHooks        ? pkgs.wrapQtAppHooks
, libsForQt5            ? pkgs.libsForQt5
, jre                   ? pkgs.jre
, libxml2               ? pkgs.libxml2
, graphviz              ? pkgs.graphviz
, webkitgtk             ? pkgs.webkitgtk
, withIDE               ? true
, withNEDDocGen         ? true
, with3dVisualization   ? true
, openscenegraph        ? pkgs.openscenegraph
, osgearth              ? null
, withParallel          ? false
, openmpi               ? pkgs.openmpi
, withPCAP              ? true
, libpcap               ? pkgs.libpcap
, doxygen               ? pkgs.doxygen
, zlib                  ? pkgs.zlib
, nemiver               ? pkgs.nemiver
, akaroa                ? null
}:

assert withIDE -> ! isNull qtbase;
assert (withIDE && withNEDDocGen) -> ! builtins.any isNull [ doxygen graphviz ];
assert with3dVisualization -> ! builtins.any isNull [ osgearth openscenegraph ];
assert withParallel -> ! builtins.any isNull [ openmpi akaroa ];
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
  version = 5.6.2;

  src = fetchFromGithub {
    owner = pname;
    repo = pname;
    rev = "${pname}-${version}";
    sha256 = "17zia5asi0y44yvw613iglsfsdyhxqn9i4sn1v4218qjqlz33iyv";
  };

  outputs = [ "out" ];

  propagatedNativeBuildInputs = [ gawk which perl bison flex file ];

  nativeBuildInputs = lib.optional withIDE [ wrapQtAppHooks ];


  dontWrapQtApps = true;
  qtWrappersArgs = [ ];

  buildInputs = [ python3 libxml2 qtbase webkitgtk zlib jre nemiver]
             ++ lib.optionals (withIDE && withNEDDocGen) [ graphviz doxygen ]
             ++ lib.optionals with3dVisualization [ openscenegraph osgearth ]
             ++ lib.optionals withParallel [ openmpi akaroa ]
             ++ lib.optional withPCAP libpcap;

  NIX_CFLAGS_COMPILE = qtbaseCFlags + libxml2CFlags;

  patches = [ ./patch.setenv
              ./patch.HOME
              ./patch.configure
              ./patch.bin
            ];

  configureFlags = [ ]
                   ++  lib.optionals (!with3dVisualization) [ "WITH_OSG=no"
                                                              "WITH_OSGEARTH=no"
                                                            ]
                   ++ lib.optional (!withParallel) "WITH_PARSIM=no";

  preConfigure = ''
    . setenv
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

    cp -r . ${placeholder "out"}

    runHook postInstall
    '';

  preFixup = ''
    (
      build_pwd=$(pwd)
      for bin in $(find ${placeholder "out"} -type f); do
        rpath=$(patchelf --print-rpath $bin  \
                | sed -E "s,:\\.:,:,g"                                                             \
                | sed -E "s,:?$build_pwd/lib:?,:${placeholder "dev"}/lib:,g"                       \
                | sed -E "s,:?$build_pwd/lib64:?,:,g"                                              \
                | sed -E "s,:?$build_pwd/samples,:${placeholder "doc"}/share/omnetpp/samples,g"    \
                | sed -E "s,:?${placeholder "out"}/lib:?,:${placeholder "dev"}/lib:,g"             \
                | sed -E "s,:+,:,g"                                                                \
                | sed -E "s,^:,,"                                                                  \
                | sed -E "s,:$,,"                                                                  \
               || echo )
        if [ -n "$rpath" ]; then
          patchelf --set-rpath "$rpath" $bin
        fi
      done
    )
    # wrapQtApp "$out/bin/myapp" --prefix PATH : /path/to/bin
    '';
}
