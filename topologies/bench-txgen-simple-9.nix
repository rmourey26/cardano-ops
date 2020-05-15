{
  coreNodes = [
    {
      name = "node-0";
      nodeId = 0;
      org = "IOHK";
      region = "eu-central-1";
      producers = ["node-1" "node-2" "node-4"];
    }
    {
      name = "node-1";
      nodeId = 1;
      org = "IOHK";
      region = "eu-central-1";
      producers = ["node-0" "node-2" "node-7"];
    }
    {
      name = "node-2";
      nodeId = 2;
      org = "IOHK";
      region = "eu-central-1";
      producers = ["node-0" "node-1"];
    }
    {
      name = "node-4";
      nodeId = 3;
      org = "IOHK";
      region = "ap-southeast-2";
      producers = ["node-5" "node-6" "node-0"];
    }
    {
      name = "node-5";
      nodeId = 4;
      org = "IOHK";
      region = "ap-southeast-2";
      producers = ["node-4" "node-6" "node-8"];
    }
    {
      name = "node-6";
      nodeId = 5;
      org = "IOHK";
      region = "ap-southeast-2";
      producers = ["node-4" "node-5"];
    }
    {
      name = "node-7";
      nodeId = 6;
      org = "IOHK";
      region = "us-east-1";
      producers = ["node-8" "node-9" "node-1"];
    }
    {
      name = "node-8";
      nodeId = 7;
      org = "IOHK";
      region = "us-east-1";
      producers = ["node-7" "node-9" "node-5"];
    }
    {
      name = "node-9";
      nodeId = 8;
      org = "IOHK";
      region = "us-east-1";
      producers = ["node-7" "node-8"];
    }
  ];

  relayNodes = [];

  legacyCoreNodes = [];

  legacyRelayNodes = [];

  byronProxies = [];
}
