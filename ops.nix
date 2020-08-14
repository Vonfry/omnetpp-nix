{ stdenv, fetchFromGitHub, perl, omnetpp, inet, wrapQtAppsHook, keetchi,
  buildMode ? "release" }:

let
  src = fetchFromGitHub {
    name = "source-ops";
    owner = "ComNets-Bremen";
    repo = "OPS";
    rev = "41fbe75280274b42ebb763d78ac6fd1f77c1b564";
    sha256 = "04f07p7x8rcydm93ywhis0lg19rih6gikimarxkq9lyz0al62yvr";
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
  };

  OMNETPP_IMAGE_PATH = [ "./images"
                         "./bitmaps"
                         "${inet_}/share/images"
                         "${inet_}/share/images"
                       ];
  NEDPATH = [ "${placeholder "out"}/src"
              "${placeholder "out"}/simulations"
              "${inet_}/src"
              "${inet_}/examples"
            ];
in

with stdenv.lib;
stdenv.mkDerivation {

  pname = "ops";
  version = "20200805";

  inherit src;
  nativeBuildInputs = [ omnetpp wrapQtAppsHook perl ];

  propagatedBuildInputs = [ keetchi inet_ ];

  inet = inet_;

  configurePhase = ''
    INET_PATH=${inet_}/src

    # Run opp_makemake manual instead of make makefiles
    # Because we need to pass link path

    OPS_MODEL_NAME=ops-simu

    KEETCHI_BUILD=true
    KEETCHI_API_PATH=${keetchi}/include
    KEETCHI_API_LIB=${keetchi}/lib

    INET_BUILD=true
    INET_PATCH=true
    INET_LIB=$INET_PATH
    INET_NED=$INET_PATH
    INET_VERSION="v4.1.1"
    SWIM_PATH=res/inet-models/SWIMMobility
    EXTENDED_SWIM_PATH=res/inet-models/ExtendedSWIMMobility
    OMNET_INI_FILE=simulations/omnetpp-herald-epidemic.ini
    OMNET_OUTPUT_DIR=./out/
    MERGE_LOG_FILES="n"

    cd src
    opp_makemake -r --deep -I$KEETCHI_API_PATH -I$INET_PATH -L$KEETCHI_API_LIB -L$INET_PATH -lkeetchi -lINET --mode ${buildMode} -o $OPS_MODEL_NAME -f
    cd ..
    opp_makemake -r --deep -I$KEETCHI_API_PATH -I$INET_PATH -L$KEETCHI_API_LIB -L$INET_PATH -lkeetchi -lINET --mode ${buildMode} -o $OPS_MODEL_NAME -f
    '';

  enableParallelBuilding = true;
  dontStrip = true;

  makeFlags = [ "MODE=${buildMode}" ];

  installPhase = ''
    rm -rf out
    rm -rf inet/out
    cp -r . ${placeholder "out"}
    mkdir ${placeholder "out"}/lib ${placeholder "out"}/bin ${placeholder "out"}/include
    ln -s ${placeholder "out"}/inet/bin/*    ${placeholder "out"}/bin/
    ln -s ${placeholder "out"}/inet/src/*.so ${placeholder "out"}/lib/
    ln -s ${placeholder "out"}/inet/src/inet ${placeholder "out"}/include/inet
    ln -s ${placeholder "out"}/ops-simu ${placeholder "out"}/bin/
    '';

  preFixup = ''
    build_pwd=$(pwd)
    patchelf --set-rpath \
      $(patchelf --print-rpath ${placeholder "out"}/ops-simu \
        | sed -E "s,$build_pwd,${placeholder "out"},g") \
      ${placeholder "out"}/ops-simu
    '';

  postFixup = ''
    wrapQtApp ${placeholder "out"}/ops-simu \
        --prefix OMNETPP_IMAGE_PATH ";" "${concatStringsSep ";" OMNETPP_IMAGE_PATH}" \
        --prefix NEDPATH ";" "${concatStringsSep ";" NEDPATH}" \
        --set QT_STYLE_OVERRIDE ${omnetpp.QT_STYLE_OVERRIDE}
    '';

}
