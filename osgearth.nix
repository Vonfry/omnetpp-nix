{ lib
, stdenv
, fetchFromGitHub
, cmake
, curl
, gdal
, openscenegraph
, geos
, qtbase
, sqlite
, libzip
}:

stdenv.mkDerivation rec {
  pname = "osgearth";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "gwaldron";
    repo = pname;
    rev = version;
    sha256 = "045x31nn51fsmswhhgmc16wdn6b4dxnfb7w3a0zp2s5q2f92d21k";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ qtbase openscenegraph gdal geos sqlite sqlite curl ];

  enableParallelBuilding = true;

  outputs = [ "out" ];

  meta = with lib; {
    homepage = "http://osgearth.org";
    description = "osgEarth is a C++ geospatial SDK and terrain engine. Just create a simple XML file, point it at your map data, and go! osgEarth supports all kinds of data and comes with lots of examples to help you get up and running quickly and easily.";
    license = licenses.lgpl3;
    platforms = platforms.unix;
  };
}
