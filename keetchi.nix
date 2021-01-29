{ stdenv, perl, fetchFromGitHub, autoreconfHook, withDoc ? false
, texlive, doxygen }:

with stdenv;
let
  texlive_ = texlive.combine {
    inherit (texlive ) scheme-medium collection-latexextra;
  };
in mkDerivation {
  name = "keetchi";
  version = "20200805";

  src = fetchFromGitHub {
    owner = "ComNets-Bremen";
    repo = "KeetchiLib";
    rev = "11cee99312ae590c2830c7f2215a3ca97bb355d3";
    sha256 = "0vx0kqlngpbhzlbsvjjlrslvkqz6rslqnsxk02fzkgnwxa6rvgbn";
  };

  nativeBuildInputs = [ autoreconfHook ]
                   ++ lib.optionals withDoc [ doxygen perl
                                              texlive_
                                            ];

  postBuild = lib.optionalString withDoc ''
    make doxygen-doc
  '';

  postInstall = ''
    cp lib/*.h ${placeholder "out"}/include
    ${lib.optionalString withDoc "cp -r doxygen-doc ${placeholder "out"}/doc"}
  '';
}
