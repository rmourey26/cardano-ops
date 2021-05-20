pkgs: with pkgs; with lib; with topology-lib {
    a = { name = "eu-central-1";   # Europe (Frankfurt);
    };
    b = { name = "us-east-2";      # US East (Ohio)
    };
    c = { name = "ap-southeast-1"; # Asia Pacific (Singapore)
    };
    d = { name = "eu-west-2";      # Europe (London)
    };
    e = { name = "us-west-1";      # US West (N. California)
    };
    f = { name = "ap-northeast-1"; # Asia Pacific (Tokyo)
    };
  };
let

  nodes = with regions; map (composeAll [
    (withAutoRestartEvery 6)
    (withModule {
      services.cardano-node = {
        # asserts = true;
        useNewTopology = true;
        package = cardanoNodeServicePkgs.cardanoNodeHaskellPackages.cardano-node.components.exes.cardano-node;
        systemdSocketActivation = mkForce false;
      };
    })
  ]) (concatLists [
    (mkStakingPoolNodes "a" 1 "d" "P2P1" { org = "IOHK"; nodeId = 2; })
    (mkStakingPoolNodes "b" 2 "e" "P2P2" { org = "IOHK"; nodeId = 3; })
    (mkStakingPoolNodes "c" 3 "f" "P2P3" { org = "IOHK"; nodeId = 4; })
  ] ++ [
    (mkBftCoreNode "a" 1 { org = "IOHK"; nodeId = 1; })
  ]);

  relayNodes = fullyConnectNodes
    (filter (n: !(n ? stakePool)) nodes);

  coreNodes = filter (n: n ? stakePool) nodes;

in {

  inherit coreNodes relayNodes;

  monitoring = {
    services.monitoring-services.publicGrafana = false;
    services.nginx.virtualHosts."monitoring.${globals.dnsZone}".locations."/p" = {
      root = ../static/pool-metadata;
    };
  };

}
