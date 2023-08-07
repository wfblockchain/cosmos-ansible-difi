check_hash()
{
  # $1: tx hash
  # $2: binary
  # $3: home folder
  txhash=$1
  code=$($2 q tx $txhash -o json --home $3 | jq '.code')
  $2 q tx $txhash -o json --home $3
  if [ $code -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}

submit_tx()
{
    # $1: transaction
    # $2: binary
    # $3: home folder
    full_tx="$2 $1 --home $3"
    echo $full_tx
    hash=$($full_tx | jq -r '.txhash')
    check=$(check_hash $hash $2 $3)
    echo "The return code is $check"
    if [[ $check -eq 1 ]]; then
      printf "Transaction failed:\n$1\n"
      exit 1
    fi
}
