let pkgs = import <nixpkgs> {}; in
{ stdenv ? pkgs.stdenv
, fetchFromGitHub ? pkgs.fetchFromGitHub
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

  src = fetchFromGitHub {
    owner = "gwaldron";
    repo = pname;
    rev = version;
    sha256 = "09i67rhyfg1fsqkj9jgld3zm2ivvbsnm8hmw3ly3fdvkc8cqlcqn";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ qtbase openscenegraph gdal geos sqlite sqlite curl ];

  outputs = [ "out" ];

  meta = with stdenv.lib; {
    homepage = "http://osgearth.org";
    description = "osgEarth is a C++ geospatial SDK and terrain engine. Just create a simple XML file, point it at your map data, and go! osgEarth supports all kinds of data and comes with lots of examples to help you get up and running quickly and easily.";
    license = licenses.lgpl3;
    platforms = platforms.unix;
  };
}
