{ stdenv, fetchFromGitHub, perl, omnetpp, inet, wrapQtAppsHook, keetchi,
  buildMode ? "release" }:

let
  src = fetchFromGitHub {
    name = "source-ops";
    owner = "ComNets-Bremen";
    repo = "OPS";
    rev = "424d53cfa7da7ebc0bb1f743e4e6aeda426f782a";
    sha256 = "13pryyqb9kv1q1vjgmgmpy9mg68glf8mjmgmhvm0vs5f0iny94vc";
  };

  inet_ = inet.override {
    copyFiles  = {
      "src/inet/mobility/single/" = [
        "${src}/res/inet-models/ExtendedSWIMMobility/ExtendedSWIM*.{cc,h,ned}"
        "${src}/res/inet-models/SWIMMobility/*.{cc,h,ned}"
      ];
      "src/inet/mobility/contract/" =
        "${src}/res/inet-models/ExtendedSWIMMobility/IReactive*.{h,ned}";
    };
    inherit buildMode;
  };

  OMNETPP_IMAGE_PATH = [ "./images"
                         "./bitmaps"
                         "${omnetpp}/share/images"
                         "${inet_}/images"
                       ];
  NEDPATH = [ "${placeholder "out"}/src"
              "${placeholder "out"}/simulations"
              "${inet_}/src"
              "${inet_}/examples"
            ];
  binSuffix = if buildMode == "debug" then "_dbg" else "";
in

with stdenv.lib;
stdenv.mkDerivation {

  pname = "ops";
  version = "20200805";

  inherit src;

  nativeBuildInputs = [ wrapQtAppsHook perl ];

  propagatedBuildInputs = [ omnetpp keetchi inet_ ];

  inet = inet_;

  configurePhase = ''
    INET_PATH=${inet_}/src

    # Run opp_makemake manual instead of make makefiles
    # Because we need to pass link path

    KEETCHI_BUILD=true
    KEETCHI_API_PATH=${keetchi}/include
    KEETCHI_API_LIB=${keetchi}/lib

    INET_BUILD=true
    INET_LIB=$INET_PATH
    INET_NED=$INET_PATH
    INET_VERSION="v4.1.1"
    SWIM_PATH=res/inet-models/SWIMMobility
    EXTENDED_SWIM_PATH=res/inet-models/ExtendedSWIMMobility
    OMNET_INI_FILE=simulations/omnetpp-herald-epidemic.ini
    OMNET_OUTPUT_DIR=./out/
    MERGE_LOG_FILES="n"

    cd src
    opp_makemake -r --deep -I$KEETCHI_API_PATH -I$INET_PATH -L$KEETCHI_API_LIB -L$INET_PATH -lkeetchi -lINET${binSuffix} --mode ${buildMode} --make-so -o ops -f
    cd ..
    opp_makemake -r --deep -I$KEETCHI_API_PATH -I$INET_PATH -L$KEETCHI_API_LIB -L$INET_PATH -lkeetchi -lINET${binSuffix} --mode ${buildMode} -o ops-simu -f
    '';

  enableParallelBuilding = true;
  dontStrip = true;

  makeFlags = [ "MODE=${buildMode}" ];

  dontWrapQtApps = true;

  postBuild = ''
    (
      cd src
      make MODE=${buildMode}
    )
  '';

  installPhase = ''
    rm -rf out
    rm -rf inet/out
    cp -r . ${placeholder "out"}
    mkdir ${placeholder "out"}/lib ${placeholder "out"}/bin ${placeholder "out"}/include
    ln -s ${placeholder "out"}/src/*.{h,ned}   ${placeholder "out"}/include/
    ln -s ${placeholder "out"}/ops-simu${binSuffix}       ${placeholder "out"}/bin/
    ln -s ${placeholder "out"}/src/*.so                   ${placeholder "out"}/lib/
    '';

  preFixup = ''
    build_pwd=$(pwd)
    patchelf --set-rpath \
      $(patchelf --print-rpath ${placeholder "out"}/ops-simu${binSuffix} \
        | sed -E "s,$build_pwd,${placeholder "out"},g") \
      ${placeholder "out"}/ops-simu${binSuffix}
    '';

  postFixup = ''
    for f in ${placeholder "out"}/bin/* ${placeholder "out"}/ops-simu${binSuffix}; do
      wrapQtApp $f \
          --prefix OMNETPP_IMAGE_PATH ";" "${concatStringsSep ";" OMNETPP_IMAGE_PATH}" \
          --prefix NEDPATH ";" "${concatStringsSep ";" NEDPATH}" \
          --set QT_STYLE_OVERRIDE ${omnetpp.QT_STYLE_OVERRIDE}
    done
    '';

}
