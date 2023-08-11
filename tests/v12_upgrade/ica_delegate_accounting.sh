#!/bin/bash
# ICA delegation accounting tests

delegation=10000000
undelegation=5000000
redelegation=2000000

echo "** Test case 1: Delegation increases validator liquid shares and global liquid staked tokens **"
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
pre_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
pre_delegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
pre_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
exchange_rate=$(echo "$pre_delegation_shares/$pre_delegation_tokens" | bc -l)
expected_liquid_increase=$(echo "$exchange_rate*$delegation" | bc -l)

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > acct-del-1.json
jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' acct-del-1.json > acct-del-2.json
jq -r --arg AMOUNT "$delegation"'.amount.amount = "AMOUNT"' acct-del-2.json > acct-del-3.json
cat acct-del-3.json
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat acct-del-3.json)" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
echo "Waiting for delegation to go on-chain..."
sleep 10

$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
post_delegation_tokens=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens'
post_delegation_liquid_shares=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares'

tokens_delta=$(($post_delegation_tokens-$pre_delegation_tokens))
liquid_shares_delta=$(echo "$post_delegation_liquid_shares-$pre_delegation_liquid_shares" | bc -l)
echo "Expected increase in liquid shares: $expected_liquid_increase"
echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta"

echo "** Test case 2: Undelegation decreases validator liquid shares and global liquid staked tokens **"
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
pre_undelegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
pre_undelegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
pre_undelegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
exchange_rate=$(echo "$pre_undelegation_shares/$pre_undelegation_tokens" | bc -l)
expected_liquid_decrease=$(echo "$exchange_rate*$undelegation" | bc -l)

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-undelegate.json > acct-undel-1.json
jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' acct-undel-1.json > acct-undel-2.json
jq -r --arg AMOUNT "$undelegation"'.amount.amount = "AMOUNT"' acct-undel-2.json > acct-undel-3.json

at acct-undel-3.json
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat acct-undel-3.json)" > undelegate_packet.json
echo "Sending tx staking undelegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 undelegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
echo "Waiting for undelegation to go on-chain..."
sleep 10

$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
post_undelegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
post_undelegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')

tokens_delta=$(($post_undelegation_tokens-$pre_undelegation_tokens))
liquid_shares_delta=$(echo "$post_undelegation_liquid_shares-$pre_undelegation_liquid_shares" | bc -l)
echo "Expected increase in liquid shares: $expected_liquid_decrease"
echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta"

echo "** Test case 3: Redelegation decreases source validator liquid shares and increases destination validator liquid shares **"
$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
pre_redelegation_tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.tokens')
pre_redelegation_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
pre_redelegation_liquid_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
pre_redelegation_tokens_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
pre_redelegation_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
pre_redelegation_liquid_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-redelegate.json > acct-redel-1.json
jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' acct-redel-1.json > acct-undel-2.json
jq -r --arg AMOUNT "$undelegation"'.amount.amount = "AMOUNT"' acct-redel-2.json > acct-undel-3.json


$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
post_undelegation_tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.tokens')
post_undelegation_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
post_undelegation_liquid_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
post_redelegation_tokens_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
post_redelegation_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
post_redelegation_liquid_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')