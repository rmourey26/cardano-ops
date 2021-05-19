#!/usr/bin/env bash
#
# Create the genesis file for the Shelley testnet, and the different keys that
# the nodes use.
#
# Keys and genesis files are placed in the `keys` directory.
#
# This script requires the following environment variables to be defined:
#
# - NB_BFT_NODES: number of BFT nodes
# - NB_POOL_NODES: number of staking pool nodes
# - K: the security parameter for the network
# - F: the active slot coefficient
# - MAX_SUPPLY: total lovelace supply
#
set -euo pipefail

cd "$(dirname "$0")/.."

[ -z ${NB_BFT_NODES+x} ] && (echo "Environment variable NB_BFT_NODES must be defined"; exit 1)
[ -z ${NB_POOL_NODES+x} ] && (echo "Environment variable NB_POOL_NODES must be defined"; exit 1)
[ -z ${K+x} ] && (echo "Environment variable K must be defined"; exit 1)
[ -z ${F+x} ] && (echo "Environment variable F must be defined"; exit 1)
[ -z ${MAX_SUPPLY+x} ] && (echo "Environment variable MAX_SUPPLY must be defined"; exit 1)
[ -z ${SLOT_LENGTH+x} ]&& ( echo "Environment variable SLOT_LENGTH must be defined"; exit 1)
[ -z ${NETWORK_MAGIC+x} ]&& ( echo "Environment variable NETWORK_MAGIC must be defined"; exit 1)

DELAY="${DELAY:-30}"

echo "Generating new genesis and keys using following environments variables:

 NB_BFT_NODES=$NB_BFT_NODES (number of bft core nodes)
 NB_POOL_NODES=$NB_POOL_NODES (number of staking pool nodes)
 K=$K (Security parameter)
 F=$F (Active slots coefficient)
 MAX_SUPPLY=$MAX_SUPPLY (Max Lovelace supply)
 SLOT_LENGTH=$SLOT_LENGTH
 NETWORK_MAGIC=$NETWORK_MAGIC
 DELAY=$DELAY (delay in minutes before genesis systemStart)
"

export NB_CORE_NODES=$(($NB_BFT_NODES + $NB_POOL_NODES))

mkdir -p keys
cd keys

if [ -f "$GENESIS_PATH" ]; then
  cat $GENESIS_PATH > ./genesis.spec.json
fi

cardano-cli genesis create-staked \
            --genesis-dir . \
            --supply $(($NB_BFT_NODES * (2 * $MAX_SUPPLY / 3) / $NB_CORE_NODES)) \
            --supply-delegated $(($NB_POOL_NODES * (2 * $MAX_SUPPLY / 3) / $NB_POOL_NODES)) \
            --gen-genesis-keys $NB_BFT_NODES \
            --gen-pools $NB_POOL_NODES \
            --gen-stake-delegs $NB_POOL_NODES \
            --gen-utxo-keys 3 \
            --start-time `date -u -d "today + 30 minutes" +'%Y-%m-%dT%H:%M:%SZ'` \
            --testnet-magic $NETWORK_MAGIC

# Customize the genesis file
#
# The epoch length must satisfy:
#
#    10 * securityParam / activeSlotsCoeff <= epochLength
#
# so we set the epoch length to exactly the value of the left hand side of the
# inequality.
EPOCH_LENGTH=`perl -E "say ((10 * $K) / $F)"`
# jq will convert the big nunbers to scientific notation, and old versions of
# nix cannot handle this. Hence we need to use sed.
sed -Ei "s/^([[:blank:]]*\"updateQuorum\":)([[:blank:]]*[^,]*,)$/\1 $NB_BFT_NODES,/" genesis.json
sed -Ei "s/^([[:blank:]]*\"epochLength\":)([[:blank:]]*[^,]*,)$/\1 $EPOCH_LENGTH,/" genesis.json
sed -Ei "s/^([[:blank:]]*\"slotLength\":)([[:blank:]]*[^,]*,)$/\1 $SLOT_LENGTH,/" genesis.json
sed -Ei "s/^([[:blank:]]*\"securityParam\":)([[:blank:]]*[^,]*)$/\1 $K/" genesis.json
sed -Ei "s/^([[:blank:]]*\"activeSlotsCoeff\":)([[:blank:]]*[^,]*,)$/\1 $F,/" genesis.json
sed -Ei "s/^([[:blank:]]*\"maxLovelaceSupply\":)([[:blank:]]*[^,]*,)$/\1 $MAX_SUPPLY,/" genesis.json

cardano-cli genesis hash --genesis genesis.json > GENHASH

#mkdir -p pool-keys
#cd pool-keys
## Create cold and VRF keys for the pool nodes
#for i in `seq $(($NB_BFT_NODES+1)) $NB_CORE_NODES`; do
#  cardano-cli node key-gen \
#        --cold-verification-key-file node$i-cold.vkey \
#        --cold-signing-key-file node$i-cold.skey \
#        --operational-certificate-issue-counter-file node$i-cold.counter
#
#  cardano-cli node key-gen-VRF \
#        --verification-key-file node$i-vrf.vkey \
#        --signing-key-file node$i-vrf.skey
#done
#cd ..
#
mkdir -p node-keys
cd node-keys
# Link VRF keys for the BFT nodes.
for i in `seq 1 $NB_BFT_NODES`; do
  ln -sf ../delegate-keys/delegate$i.vrf.skey node-vrf$i.skey
  ln -sf ../delegate-keys/delegate$i.vrf.vkey node-vrf$i.vkey
done
# Link VRF keys for the staking pool nodes.
for p in `seq 1 $NB_POOL_NODES`; do
  i=$(($NB_BFT_NODES+p))
  ln -sf ../pools/vrf$p.skey node-vrf$i.skey
  ln -sf ../pools/kes$p.skey node-kes$i.skey
  ln -sf ../pools/opcert$p.cert node$i.opcert
done
# TODO fix script:
#../../scripts/renew-kes-keys.sh 0
#
