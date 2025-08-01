{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          emacsConfiguration = pkgs.runCommand "emacs-config" { } ''
            mkdir -p $out
            ln -s ${./emacs-config.el} $out/init.el
          '';

          emacs = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (
            epkgs: with epkgs; [
              evil
              proof-general
            ]
          );
          wrappedEmacs = pkgs.runCommand "emacs" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
            makeWrapper ${emacs}/bin/emacs $out/bin/emacs --add-flags '--init-directory ${emacsConfiguration}'
          '';

          coqPackages = pkgs.coqPackages;
        in
        {
          default = pkgs.mkShell {
            packages = [
              wrappedEmacs

              coqPackages.coq
              coqPackages.fourcolor
              coqPackages.mathcomp-analysis
              coqPackages.mathcomp-algebra-tactics
            ];
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        treefmtEval.config.build.wrapper
      );
    };
}
