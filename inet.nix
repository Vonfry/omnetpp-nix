{ stdenv, fetchFromGitHub, perl, omnetpp, wrapQtAppsHook, buildMode ? "release",
  copyFiles ? {}
}:

with stdenv; with lib;
let

  copyFromAttrs = files:
    let
      cp = to: from: "cp -rf ${from} ${to}";
      f = name: value:
        if isList value
          then map (cp name) value
          else cp name value;
    in concatStringsSep "\n" (flatten (mapAttrsToList f files));

in mkDerivation rec {

  pname = "INet";
  version = "v4.2.0";

  src = fetchFromGitHub {
    name = "source-inet";
    owner = "inet-framework";
    repo = "inet";
    rev = version;
    sha256 = "1aqbnjbxz05xamkdmfqbqf0vz1z8n5wnkh6k41gg7rri7kjb6453";
  };

  nativeBuildInputs = [ wrapQtAppsHook perl ];
  propagatedBuildInputs = [ omnetpp ];

  configurePhase = ''
    runHook preConfigure

    ${copyFromAttrs copyFiles}

    export INET_ROOT=`pwd`
    echo $INET_ROOT
    export PATH=$INET_ROOT/bin:$PATH
    export INET_NED_PATH="$INET_ROOT/src:$INET_ROOT/tutorials:$INET_ROOT/showcases:$INET_ROOT/examples"
    export INET_OMNETPP_OPTIONS="-n $INET_NED_PATH --image-path=$${placeholder "out"}/share/images"
    export INET_GDB_OPTIONS="-quiet -ex run --args"
    export INET_VALGRIND_OPTIONS="-v --tool=memcheck --leak-check=yes --show-reachable=no --leak-resolution=high --num-callers=40 --freelist-vol=4000000"
    make makefiles

    runHook postConfigure
    '';

  enableParallelBuilding = true;
  dontStrip = true;

  makeFlags = [ "MODE=${buildMode}" ];

  installPhase = ''
    runHook preInstall

    rm -rf out
    rm -rf inet/out
    cp -r . ${placeholder "out"}
    mkdir -p ${placeholder "out"}/lib ${placeholder "out"}/include
    ln -s ${placeholder "out"}/src/*.so ${placeholder "out"}/lib/
    ln -s ${placeholder "out"}/src/inet ${placeholder "out"}/include/inet

    runHook postInstall
    '';

  postFixup = ''
    for f in ${placeholder "out"}/bin/*; do
      wrapProgram $f \
        --prefix OMNETPP_IMAGE_PATH ";" "./images;./bitmaps;${omnetpp}/share/images;${placeholder "out"}/share/images" \
        --set QT_STYLE_OVERRIDE fusion
    done
    '';

}
