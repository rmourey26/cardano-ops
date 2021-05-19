pkgs: with pkgs.iohkNix.cardanoLib; with pkgs.globals; {

  # This should match the name of the topology file.
  deploymentName = "p2p";

  environmentConfig = rec {
    relaysNew = "relays.${domain}";
    genesisFile = ./keys/genesis.json;
    genesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
    nodeConfig =
      pkgs.lib.recursiveUpdate
      environments.shelley_qa.nodeConfig
      {
        ShelleyGenesisFile = genesisFile;
        ShelleyGenesisHash = genesisHash;
        Protocol = "TPraos";
        TraceTxInbound = true;
        TestAllegraHardForkAtEpoch = 1;
        TestMaryHardForkAtEpoch = 2;
      };
    explorerConfig = mkExplorerConfig environmentName nodeConfig;
  };

  ec2 = {
    credentials = {
      accessKeyIds = {
        IOHK = "default";
        dns = "dev";
      };
    };
  };
}
