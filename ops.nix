let pkgs = import <nixpkgs> {};
in
{ stdenv ? pkgs.stdenv
, fetchFromGitHub ? pkgs.fetchFromGitHub}:

stdenv.mkDerivation rec {
  pname = "OPS";
  version = "5.4.1";

  src = fetchFromGitHub {
    owner = "ComNets-Bremen";
    repo = pname;
    rev = "41fbe75280274b42ebb763d78ac6fd1f77c1b564";
    sha256 = "04f07p7x8rcydm93ywhis0lg19rih6gikimarxkq9lyz0al62yvr";
  };

  meta = with stdenv.lib; {
    homepage = "https://github.com/ComNets-Bremen/OPS";
    license = licenses.gpl3;
    description = "The Opportunistic Protocol Simulator (OPS, pronounced as oops!!!) is a set of simulation models for OMNeT++ to simulate opportunistic networks. It has a modular architecture where different protocols relevant to opportunistic networks can be developed and plugged in. The details of prerequisites, installing OPS, configuring OPS, simulating with OPS and much more are given in the following sections.";
    platforms = platforms.unix;
  };
}
