#!/bin/bash

set -eu

function color() {
  # Usage: color "31;5" "string"
  # Some valid values for color:
  # - 5 blink, 1 strong, 4 underlined
  # - fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
  # - bg: 40 black, 41 red, 44 blue, 45 purple
  printf '\033[%sm%s\033[0m\n' "$@"
}

if [ "$#" -lt 1 ]; then
  color "31" "Usage: ./chd.sh PROCESS FLAGS."
  color "31" "PROCESS can be init"
  exit 1
fi

system=""
case "$OSTYPE" in
  darwin*) system="darwin" ;;
  linux*) system="linux" ;;
  msys*) system="windows" ;;
  cygwin*) system="windows" ;;
  *) exit 1 ;;
esac
readonly system

architecture=""
case $(uname -m) in
  i386)    architecture="amd64" ;;
  i686)    architecture="amd64" ;;
  x86_64)  architecture="amd64" ;;
  aarch64) architecture="amd64" ;;
  arm)     architecture="arm64" ;;
esac

dirname=${PWD##*/}
chain_root="$(pwd)/chain"
if [ "$dirname" = "chain" ]; then
  chain_root="$(pwd)"
fi

if [ "$1" = "clear-side-chain" ]; then

  if [ "$system" == "linux" ]; then
    sudo rm -rf "$chain_root"/side-chain/chain
  else
    rm -rf "$chain_root"/side-chain/chain
  fi

  mkdir -p "$chain_root"/side-chain/chain

  cp -rf "$chain_root"/side-chain/config/template/* "$chain_root"/side-chain/chain/

  docker run -it -v "$chain_root"/side-chain/chain:/data -v "$chain_root"/side-chain/config:/config --name el-node --rm bosagora/agora-el-node:v2.0.1 --datadir=/data init /config/genesis.json

elif [ "$1" = "init-side-chain" ]; then

  if [ "$system" == "linux" ]; then
    sudo rm -rf "$chain_root"/side-chain/chain
  else
    rm -rf "$chain_root"/side-chain/chain
  fi

  unzip -q "$chain_root"/side-chain/chain.zip -d "$chain_root"/side-chain

elif [ "$1" = "start-side-chain" ]; then

  docker compose -f "$chain_root"/side-chain/docker-compose.yml up -d

elif [ "$1" = "stop-side-chain" ]; then

  docker compose -f "$chain_root"/side-chain/docker-compose.yml down

elif [ "$1" = "attach-side-chain" ]; then

  docker run -it -v "$chain_root"/side-chain/chain:/data -v "$chain_root"/side-chain/config:/config --name el-node-attach-side-chain --rm bosagora/agora-el-node:v2.0.1 --datadir=/data attach /data/geth.ipc

elif [ "$1" = "clear-main-chain" ]; then

  if [ "$system" == "linux" ]; then
    sudo rm -rf "$chain_root"/main-chain/chain
  else
    rm -rf "$chain_root"/main-chain/chain
  fi

  mkdir -p "$chain_root"/main-chain/chain

  cp -rf "$chain_root"/main-chain/config/template/* "$chain_root"/main-chain/chain/

  docker run -it -v "$chain_root"/main-chain/chain:/data -v "$chain_root"/main-chain/config:/config --name el-main-node --rm bosagora/agora-el-node:v2.0.1 --datadir=/data init /config/genesis.json

elif [ "$1" = "init-main-chain" ]; then

  if [ "$system" == "linux" ]; then
    sudo rm -rf "$chain_root"/main-chain/chain
  else
    rm -rf "$chain_root"/main-chain/chain
  fi

  unzip -q "$chain_root"/main-chain/chain.zip -d "$chain_root"/main-chain

elif [ "$1" = "start-main-chain" ]; then

  docker compose -f "$chain_root"/main-chain/docker-compose.yml up -d

elif [ "$1" = "stop-main-chain" ]; then

  docker compose -f "$chain_root"/main-chain/docker-compose.yml down

elif [ "$1" = "attach-main-chain" ]; then

  docker run -it -v "$chain_root"/main-chain/chain:/data -v "$chain_root"/main-chain/config:/config --name el-node-attach-main-chain --rm bosagora/agora-el-node:v2.0.1 --datadir=/data attach /data/geth.ipc

elif [ "$1" = "start-db" ]; then

  docker compose -f "$chain_root"/postgres/docker-compose.yml up -d

elif [ "$1" = "init-db" ]; then

  chmod 0600 "$chain_root"/postgres/.pgpass
  docker run -it --rm --net=host -v "$chain_root"/postgres:/src -v "$chain_root"/postgres/.pgpass:/root/.pgpass postgres:14 psql -f /src/init.sql -d postgres -h 0.0.0.0 -U agora > /dev/null

elif [ "$1" = "stop-db" ]; then

  docker compose -f "$chain_root"/postgres/docker-compose.yml down

  docker volume rm postgres_postgres_db

elif [ "$1" = "start-boa-scan" ]; then

  if [ "$architecture" == "amd64" ]; then
    docker compose -f "$chain_root"/boa-scan/docker-compose-amd64.yml up -d
  else
    docker compose -f "$chain_root"/boa-scan/docker-compose-arm64.yml up -d
  fi

elif [ "$1" = "stop-boa-scan" ]; then

  if [ "$architecture" == "amd64" ]; then
    docker compose -f "$chain_root"/boa-scan/docker-compose-amd64.yml down
  else
    docker compose -f "$chain_root"/boa-scan/docker-compose-arm64.yml down
  fi

  docker volume rm boa-scan_redis_db

elif [ "$1" = "start-ipfs" ]; then

  export CLUSTER_SECRET=$(od -vN 32 -An -tx1 /dev/urandom | tr -d ' \n')
  echo $CLUSTER_SECRET

  docker compose -f "$chain_root"/ipfs-private/docker-compose.yml up -d

elif [ "$1" = "stop-ipfs" ]; then

  docker compose -f "$chain_root"/ipfs-private/docker-compose.yml down

  docker volume rm ipfs-private_node0_ipfs
  docker volume rm ipfs-private_node0_ipfs_cluster
  docker volume rm ipfs-private_node1_ipfs
  docker volume rm ipfs-private_node1_ipfs_cluster
  docker volume rm ipfs-private_node2_ipfs
  docker volume rm ipfs-private_node2_ipfs_cluster

elif [ "$1" = "start-relay" ]; then

  docker compose -f "$chain_root"/relay/docker-compose.yml up -d

elif [ "$1" = "stop-relay" ]; then

  docker compose -f "$chain_root"/relay/docker-compose.yml down

elif [ "$1" = "start-save-purchase" ]; then

  docker compose -f "$chain_root"/save-purchase/docker-compose.yml up -d

elif [ "$1" = "stop-save-purchase" ]; then

  docker compose -f "$chain_root"/save-purchase/docker-compose.yml down

elif [ "$1" = "start-save-purchase-client" ]; then

  docker compose -f "$chain_root"/save-purchase-client/docker-compose.yml up -d

elif [ "$1" = "stop-save-purchase-client" ]; then

  docker compose -f "$chain_root"/save-purchase-client/docker-compose.yml down

elif [ "$1" = "start-phone-link-validator" ]; then

  docker compose -f "$chain_root"/phone-link-validator/docker-compose.yml up -d

elif [ "$1" = "stop-phone-link-validator" ]; then

  docker compose -f "$chain_root"/phone-link-validator/docker-compose.yml down

elif [ "$1" = "start-sms" ]; then

  docker compose -f "$chain_root"/sms/docker-compose.yml up -d

elif [ "$1" = "stop-sms" ]; then

  docker compose -f "$chain_root"/sms/docker-compose.yml down

elif [ "$1" = "start-graph" ]; then

  docker compose -f "$chain_root"/graph/docker-compose.yml up -d

elif [ "$1" = "stop-graph" ]; then

  docker compose -f "$chain_root"/graph/docker-compose.yml down

elif [ "$1" = "start-validator" ]; then

  docker compose -f "$chain_root"/validator/docker-compose.yml up -d

elif [ "$1" = "stop-validator" ]; then

  docker compose -f "$chain_root"/validator/docker-compose.yml down

elif [ "$1" = "start-bridge" ]; then

  docker compose -f "$chain_root"/bridge/docker-compose.yml up -d

elif [ "$1" = "stop-bridge" ]; then

  docker compose -f "$chain_root"/bridge/docker-compose.yml down

elif [ "$1" = "create-network" ]; then

  docker network create --subnet=172.200.0.0/16 bosagora_network

elif [ "$1" = "remove-network" ]; then

  docker network rm bosagora_network

elif [ "$1" = "deploy-subgraph-sidechain" ]; then

  CURRENT_POS="$(pwd)"

  dirname2=${PWD##*/}
  if [ "$dirname2" = "chain" ]; then
    cd ../submodules/dms-osx
  else
    cd submodules/dms-osx
  fi

  yarn install

  cd packages/subgraph-sidechain
  yarn run build:contracts
  yarn run manifest
  yarn run build
  yarn run create:sidechain

  npx graph deploy acc-coin/acc-osx-sidechain --node http://localhost:8020 --ipfs http://localhost:5001 --version-label v0.0.1

  cd "$CURRENT_POS"

elif [ "$1" = "deploy-subgraph-mainchain" ]; then

  CURRENT_POS="$(pwd)"

  dirname2=${PWD##*/}
  if [ "$dirname2" = "chain" ]; then
    cd ../submodules/dms-osx
  else
    cd submodules/dms-osx
  fi

  yarn install

  cd packages/subgraph-mainchain
  yarn run build:contracts
  yarn run manifest
  yarn run build
  yarn run create:mainchain

  npx graph deploy acc-coin/acc-osx-mainchain --node http://localhost:8020 --ipfs http://localhost:5001 --version-label v0.0.1

  cd "$CURRENT_POS"

elif [ "$1" = " save-sample-purchase" ]; then

  CURRENT_POS="$(pwd)"

  dirname2=${PWD##*/}
  if [ "$dirname2" = "chain" ]; then
    cd ../submodules/dms-save-purchase
  else
    cd submodules/dms-save-purchase
  fi

  yarn install

  cd packages/server

  SERVER_URL="http://localhost:3030" ACCESS_KEY="0x2c93e943c0d7f6f1a42f53e116c52c40fe5c1b428506dc04b290f2a77580a342" CURRENCY="php" npx ts-node scripts/store_all.ts

  cd "$CURRENT_POS"

else

  color "31" "Process '$1' is not found!"
  color "31" "Usage: ./cmd.sh PROCESS FLAGS."
  color "31" "PROCESS can be init"
  exit 1

fi
