## Buy Say Sell

The Buy Say Sell smart contract in Solidity.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil --block-time 10
```

Add some dummy data:

```shell
$ forge script script/Populate.s.sol  --rpc-url http://127.0.0.1:8545 --broadcast
```

### Deploy

Manually input private key:

```shell
$ forge script script/BuySaySell.s.sol --rpc-url <your-rpc-url> --broadcast -i 1
```
