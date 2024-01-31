// import { ContractFunctionExecutionError } from "viem";
import { logger } from "../utils"
import fs from 'fs'
import { ApiPromise, WsProvider } from '@polkadot/api';
import { stringToU8a, u8aToHex, u8aConcat, hexToU8a } from '@polkadot/util'
import { Keyring } from '@polkadot/keyring'
import { cryptoWaitReady } from '@polkadot/util-crypto'
import { OnChainRegistry, getClient, getContract, KeyringPairProvider, AbiLike } from '@phala/sdk'
import { stringToHex } from "viem";

const KEY = <`0x${string}`> process.env.PC_PRIVKEY
const CONTRACT = <`0x${string}`> process.env.PC_FACTORY

let client: OnChainRegistry
let contract: unknown

function readAbi(): AbiLike {
    const abi = fs.readFileSync('./src/chain/pcAbi.json', {encoding: 'utf-8'})
    return JSON.parse(abi)
}

export async function connect(): Promise<void> {
    if (contract && client) {
        return
    }
    // Connect to Substrate
    const wsApiProvider = new WsProvider('wss://poc6.phala.network/ws');
    const api = await ApiPromise.create({ provider: wsApiProvider, noInitWarn: true });
    await cryptoWaitReady()
    // Create key provider
    const keyring = new Keyring({ type: 'sr25519', ss58Format: 30 });
    const key = keyring.addFromSeed(hexToU8a(KEY));
    const provider = await KeyringPairProvider.create(api, key)
    console.log('Phala Address:', provider.address)
    // Create contract clients
    client = await getClient({ transport: 'wss://poc6.phala.network/ws' })
    contract = await getContract({
      client,
      contractId: CONTRACT,
      abi: readAbi(),
      provider,
    })
}

export async function deploy(owner: `0x${string}`, mid: string, expiration: number): Promise<void> {
    logger.log(`deploy(${mid}, ${expiration})`)
    const hexDeploymentId = stringToHex(mid)
    const rawAddress = u8aToHex(u8aConcat(hexToU8a(owner), stringToU8a('@evm_address')))
    // @ts-ignore
    await contract.exec.createUser({ args: [rawAddress, hexDeploymentId, expiration] })
}

export async function checkMinerDeployed(mid: string): Promise<[boolean, string | undefined]> {
    logger.log(`checkMinerDeployed(${mid})`)
    const hexDeploymentId = stringToHex(mid)

    // @ts-ignore
    const { output } = await contract.q.getWorkerInfo({ args: [hexDeploymentId] })
    if (output.isErr || output.asOk.isErr) {
        console.log(output.toJSON())
        return [false, '']
    }
    const workerInfo = output.asOk.asOk
    const address = workerInfo.instance.inner.accountId
    return [true, `phala://${address.toHex()}`]
}