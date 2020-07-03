let pkgs = import <nixpkgs> {}; in
{ stdenv ? pkgs.stdenv
, fetchFromGithub ? pkgs.fetchFromGithub
, cmake ? pkgs.cmake
, curl ? pkgs.curl
, gdal ? pkgs.gdal
, openscenegraph ? pkgs.openscenegraph
, geos ? pkgs.geos
, qtbase ? pkgs.qt5.qtbase
, sqlite ? pkgs.sqlite
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

  nativeBuildInputs = [ cmake ];
  buildInputs = [ qtbase openscenegraph gdal geos sqlite sqlite curl ];

  outputs = [ "out" ];

}
