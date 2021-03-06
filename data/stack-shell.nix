let
  inherit (import ./default.nix {}) pkgs nixageProj;
  stackCmd = ''stack --internal-re-exec-version="${pkgs.stack.version}"'';

in nixageProj.haskellPackages.shellFor {
  packages = _: pkgs.lib.attrValues nixageProj.localPackages;

  nativeBuildInputs = [ pkgs.stack pkgs.git ];
  preferLocalBuild = true;

  STACK_PLATFORM_VARIANT="nix";
  STACK_IN_NIX_SHELL=1;
  STACK_IN_NIX_EXTRA_ARGS = "";

  GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  configurePhase = ''export STACK_ROOT="$NIX_BUILD_TOP"/.stack'';
  buildPhase = ''${stackCmd} build'';
  checkPhase = ''${stackCmd} test'';
  installPhase = ''${stackCmd} --local-bin-path=$out/bin build --copy-bins'';
}
