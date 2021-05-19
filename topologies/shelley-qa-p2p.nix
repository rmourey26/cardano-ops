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
        asserts = true;
        systemdSocketActivation = mkForce false;
      };
    })
  ]) (concatLists [
    #[ (mkBftCoreNode "a" 1 { org = "IOHK"; nodeId = 1; }) ]
    (mkStakingPoolNodes 2 "d" "a" "P2P1")
    (mkStakingPoolNodes 3 "e" "b" "P2P2")
    (mkStakingPoolNodes 4 "f" "c" "P2P3")
  ]);

  relayNodes = filter (n: !(n ? stakePool)) nodes;

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
