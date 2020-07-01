{ stdenv
, fetchFromGithub
, cmake
, curl
, gdal
, openscenegraph
, geos
, qt5
, sqlite
}:

stdenv.mkDerivation rec {
  pname = "osgearth";
  version = "3.0";

  src = fetchFromGithub {
    owner = "gwaldron";
    repo = pname;
    rev = version;
    sha256 = "09i67rhyfg1fsqkj9jgld3zm2ivvbsnm8hmw3ly3fdvkc8cqlcqn";
  };

  propagatedNativeBuildInputs = [ openscenegraph ];
  nativeBuildInputs = [ cmake gdal geos sqlite sqlite ];
  buildInputs = [ qt5 ];

  outputs = [ "out" "curl" ];

}
