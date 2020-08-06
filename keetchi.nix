{ stdenv, perl, fetchFromGitHub, autoreconfHook, withDoc ? true
, texlive, doxygen }:

with stdenv;
mkDerivation {
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
                                              texlive.combined.scheme-full
                                            ];

  postBuild = lib.optionalString withDoc ''
    make doxygen-doc
    '';

  postInstall = lib.optionalString withDoc ''
    cp lib/*.h ${placeholder "out"}/include
    cp -r doxygen-doc ${placeholder "out"}/doc
    '';
}
