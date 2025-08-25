#!/bin/bash
JSON=`jq '.abi' out/BuySaySell.sol/BuySaySell.json`
FILE="export const contractAbi = ${JSON} as const;"
echo ${FILE}

