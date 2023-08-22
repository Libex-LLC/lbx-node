# Change directory into lbx-node/build

CHAIN_ID="Libex-Chain-Tigris"
PASSWORD="12345678"
workspace=/home/donk3y/Projects/lab27/lbx-node/.local

nodesNamesArr=(
	"Aconcagua" 
	"Ararat" 
  "Carrauntoohil" 
  "Elbrus" 
  "Everest" 
  "Fuji" 
  "Gahinga" 
  "Kita" 
  "Scafell" 
  "Seoraksan" 
  "Zugspitze" 
)


mkdir  ${workspace}/_genTx

for node in ${nodesNamesArr[@]}; do
  echo "Init node ${node}"

  # Make node directory
  mkdir ${workspace}/${node}

  # Create unique genesis for each node
  ./build/bnbchaind init --home ${workspace}/${node} --chain-id "${CHAIN_ID}" --moniker "$node" > ${workspace}/${node}/node.info

  # Create delegator and operator (has consensus_addr) account for each node
  echo "${PASSWORD}" | ./build/bnbcli keys add ${node}-delegator --home ${workspace}/${node} > ${workspace}/${node}/delegator.info
  echo "${PASSWORD}" | ./build/bnbcli keys add ${node} --home ${workspace}/${node} > ${workspace}/${node}/operator.info

  # Delegate funds and create genTx for delegation
  nodeID=$(cat ${workspace}/${node}/node.info | jq -r '.node_id')
  pubKey=$(cat ${workspace}/${node}/node.info | jq -r '.pub_key')
  delegator=$(./build/bnbcli keys list --home ${workspace}/${node} | grep ${node}-delegator | awk -F" " '{print $3}')

  echo "Stake funds node ${node}"
  ./build/bnbcli staking create-validator --chain-id="${CHAIN_ID}" \
    --from "${node}" --pubkey ${pubKey} --amount=1000000000:LBX \
    --moniker="${node}" --address-delegator=${delegator} --commission-rate=0 \
    --commission-max-rate=0 --commission-max-change-rate=0 --proposal-id=0 \
    --node-id=${nodeID} --genesis-format --home ${workspace}/${node} \
    --generate-only > ${workspace}/${node}/${node}-delegate-unsigned.json
       
  echo "${PASSWORD}" | ./build/bnbcli sign \
    ${workspace}/${node}/${node}-delegate-unsigned.json \
    --name "${node}-delegator" --home ${workspace}/${node} \
    --chain-id="${CHAIN_ID}" --offline > ${workspace}/${node}/${node}-delegate-signed.json

  echo "${PASSWORD}" | ./build/bnbcli sign \
    ${workspace}/${node}/${node}-delegate-signed.json \
    --name "${node}-delegator" --home ${workspace}/${node} \
    --chain-id="${CHAIN_ID}" --offline > ${workspace}/_genTx/${node}-delegate.json
done

echo "Generating global genesis.json"

# Generate gloabl genesis.json 
./build/bnbchaind collect-gentxs --acc-prefix lbx --chain-id ${CHAIN_ID} -i ${workspace}/_genTx -o ${workspace}/genesis.json

for node in ${nodesNamesArr[@]}; do
  cp ${workspace}/genesis.json
done
