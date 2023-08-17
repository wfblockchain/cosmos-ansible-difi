#!/bin/bash

source tests/process_tx.sh

liquid_1_delegations=20000000
liquid_2_delegations=150000000
liquid_2_tokenize=120000000
tokenized_denom="$VALOPER_1/2"

validator_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.validator_liquid_staking_cap')
global_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.global_liquid_staking_cap')

$CHAIN_BINARY keys add fail_liquid_acct1 --home $HOME_1
$CHAIN_BINARY keys add fail_liquid_acct2 --home $HOME_1
liquid_address_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="fail_liquid_acct1").address')
liquid_address_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="fail_liquid_acct2").address')
echo "Liquid address 1: $liquid_address_1"
echo "Liquid address 2: $liquid_address_2"

echo "Funding liquid accounts..."
submit_tx "tx bank send $WALLET_1 $liquid_address_1 1000000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address_2 1000000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Delegating with liquid acct 1..."

tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-1 $liquid_address_1 $liquid_1_delegations
submit_tx "tx staking delegate $VALOPER_1 $liquid_1_delegations$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-1 $liquid_address_1 $liquid_1_delegations

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-2 $liquid_address_1 $liquid_1_delegations
submit_tx "tx staking delegate $VALOPER_2 $liquid_1_delegations$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-2 $liquid_address_1 $liquid_1_delegations

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
echo "Delegating with liquid acct 2..."

tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-3 $liquid_address_2 $liquid_2_delegations
submit_tx "tx staking delegate $VALOPER_1 $liquid_2_delegations$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-3 $liquid_address_2 $liquid_2_delegations

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-4 $liquid_address_2 $liquid_2_delegations
submit_tx "tx staking delegate $VALOPER_2 $liquid_2_delegations$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-4 $liquid_address_2 $liquid_2_delegations
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Failure case 1: Attempt to tokenize with liquid_1 (no validator bond)..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $liquid_address_1 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

tests/v12_upgrade/log_lsm_data.sh failures pre-bond-1 $liquid_address_1 -
submit_tx "tx staking validator-bond $VALOPER_1 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-bond-1 $liquid_address_1 -
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-bond-2 $liquid_address_1 -
submit_tx "tx staking validator-bond $VALOPER_2 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-bond-2 $liquid_address_1 -
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Validator 1 bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne $liquid_1_delegations  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Validator 2 bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne $liquid_1_delegations  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

echo "Failure case 2: Attempt to tokenize bond delegations with Wliquid_1..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 $liquid_1_delegations$DENOM $liquid_address_1 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

validator_delegations=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
validator_cap=$(echo "$validator_delegations*$validator_cap_param" | bc)
echo "Validator_delegations: ${validator_delegations%.*}"
echo "Validator shares cap: ${validator_cap%.*}"

echo "Failure case 3: Attempt to tokenize with liquid_2, breaching the validator liquid staking cap..."
submit_bad_tx "tx staking tokenize-share $VALOPER_2 100000000$DENOM $liquid_address_2 --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

bonded_tokens=$($CHAIN_BINARY q staking pool --home $HOME_1 -o json | jq -r '.bonded_tokens')
global_staked=$($CHAIN_BINARY q staking total-liquid-staked --home $HOME_1 -o json | jq -r '.')
global_cap=$(echo "$bonded_tokens*$global_cap_param" | bc)
echo "Global shares cap: ${global_cap%.*}"
echo "Global staked: $global_staked"

echo "Failure case 4: Attempt to tokenize with liquid_2, breaching the global liquid staking cap..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 140000000$DENOM $liquid_address_2 --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Failure case 5: Attempt to unbond validator bond, fails because it breaches the validator bond factor"
echo "Tokenizing liquid_2 delegations..."
tests/v12_upgrade/log_lsm_data.sh failures pre-tokenize-1 $liquid_address_2 $liquid_2_tokenize
submit_tx "tx staking tokenize-share $VALOPER_1 $liquid_2_tokenize$DENOM $liquid_address_2 --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-tokenize-1 $liquid_address_2 $liquid_2_tokenize

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
echo "Attempting to unbond from liquid_1..."
submit_bad_tx "tx staking unbond $VALOPER_1 $liquid_1_delegations$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Redeeming tokens from liquid_2..."
$CHAIN_BINARY q bank balances $liquid_address_2 --home $HOME_1 -o json | jq '.balances'
tests/v12_upgrade/log_lsm_data.sh failures pre-redeem-1 $liquid_address_2 $liquid_2_tokenize
submit_tx "tx staking redeem-tokens $liquid_2_tokenize$tokenized_denom --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-redeem-1 $liquid_address_2 $liquid_2_tokenize
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Failure case 6: Attempt to tokenize with liquid_2 after disabling tokenizing..."
submit_tx "tx staking disable-tokenize-shares --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
submit_bad_tx "tx staking tokenize-share $VALOPER_1 10000000$DENOM $liquid_address_2 --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
submit_tx "tx staking enable-tokenize-shares --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

# Cleanup
echo "Unbonding delegations from liquid_1 and liquid_2..."
tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-1 $liquid_address_1 $liquid_1_delegations
submit_tx "tx staking unbond $VALOPER_1 $liquid_1_delegations$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-unbond-1 $liquid_address_1 $liquid_1_delegations
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-2 $liquid_address_1 $liquid_1_delegations
submit_tx "tx staking unbond $VALOPER_2 $liquid_1_delegations$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-unbond-2 $liquid_address_1 $liquid_1_delegations
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-3 $liquid_address_2 $liquid_2_delegations
submit_tx "tx staking unbond $VALOPER_1 $liquid_2_delegations$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-unbond-3 $liquid_address_2 $liquid_2_delegations
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-4 $liquid_address_2 $liquid_2_delegations
submit_tx "tx staking unbond $VALOPER_2 $liquid_2_delegations$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-unbond-4 $liquid_address_2 $liquid_2_delegations
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
