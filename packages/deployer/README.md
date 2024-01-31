# DePIN Deployer

## Prepare

```bash
# Create a dir
mkdir tmp
# Create .env file, and set the variables according to your setup
cp .env_example .env
# Install dependencies
yarn
```

## Run Deployer

Ensure you have:
1. Started foundry testnet
2. Deployed the contracts
3. Set the `.env` variables accordingly

```bash
yarn dev
```

## Run Encryption Demo

Ensure you have:
1. Set the `.env` variables accordingly

```bash
yarn demo
```
