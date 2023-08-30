{ mkDerivation, base, lib, mustache, shake, text }:
mkDerivation {
  pname = "plugin-scaffold";
  version = "0.1.0.0";
  src = ../.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base mustache shake text ];
  license = "unknown";
  mainProgram = "plugin-scaffold";
}
