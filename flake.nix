{
  inputs = {
    dream2nix.url =
      "github:tinybeachthor/dream2nix/fix-nodejs-link-direct-bins";
    src.url = "github:ether/etherpad-lite/develop";
    src.flake = false;
  };
  outputs = { self, dream2nix, src }@inputs:
    (dream2nix.lib.makeFlakeOutputs {
      systems = [ "x86_64-linux" ];
      config.projectRoot = ./.;
      packageOverrides = { };
      source = "${src}/src";
    }) // {
      nixosModules.etherpad = { config, lib, pkgs }:
        with lib;
        let
          cfg = config.services.etherpad;
          user = "etherpad";
          group = "etherpad";
          statePath = cfg.statePath;
        in {
          options.services.etherpad = {
            enable = mkEnableOption "Enable etherpad server";
            statePath = mkOption {
              default = "/var/lib/etherpad";
              description =
                "Folder to store runtime data (Database, uploads, etc)";
              type = types.str;
            };
            config = mkOption {
              default = "";
              description = "Etherpad configuration";
            };
          };

          config = mkIf cfg.enable {
            systemd.tmpfile.rules =
              [ "d ${statePath} 0750 ${user} ${group} - -" ];
            systemd.services.etherpad = {
              wantedBy = [ "multi-user.target" ];
              after = [ "netowrk.target" ];
              description = "Start the etherpad server.";
              serviceConfig = {
                WorkingDirectory =
                  "${etherpad}/lib/node_modules/ep_etherpad-lite/";
                ExecStart = "${pkgs.nodejs}/bin/node node/server.js";
                User = user;
                Group = group;
              };
            };
          };

        };
    };
}
