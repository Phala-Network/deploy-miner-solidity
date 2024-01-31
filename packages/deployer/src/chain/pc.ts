// import { ContractFunctionExecutionError } from "viem";
import { logger } from "../utils"
import fs from 'fs'
import { ApiPromise, WsProvider } from '@polkadot/api';
import { stringToU8a, u8aToHex, u8aConcat, hexToU8a } from '@polkadot/util'
import { Keyring } from '@polkadot/keyring'
import { cryptoWaitReady } from '@polkadot/util-crypto'
import { OnChainRegistry, getClient, getContract, KeyringPairProvider, AbiLike, PinkContractPromise } from '@phala/sdk'
import { stringToHex } from "viem";

const KEY = <`0x${string}`> process.env.PC_PRIVKEY
const CONTRACT = <`0x${string}`> process.env.PC_FACTORY

let client: OnChainRegistry
let api: ApiPromise
let contract: unknown

function readAbi(filepath: string): AbiLike {
    const abi = fs.readFileSync(filepath, {encoding: 'utf-8'})
    return JSON.parse(abi)
}

export async function connect(): Promise<void> {
    if (contract && client) {
        return
    }
    // Connect to Substrate
    const wsApiProvider = new WsProvider('wss://poc6.phala.network/ws');
    api = await ApiPromise.create({ provider: wsApiProvider, noInitWarn: true });
    await cryptoWaitReady()
    // Create key provider
    const keyring = new Keyring({ type: 'sr25519', ss58Format: 30 });
    const key = keyring.addFromSeed(hexToU8a(KEY));
    const provider = await KeyringPairProvider.create(api, key)
    logger.log('Phala Address:', provider.address)
    // Create contract clients
    client = await getClient({ transport: 'wss://poc6.phala.network/ws' })
    contract = await getContract({
      client,
      contractId: CONTRACT,
      abi: readAbi('./src/chain/pcAbi.json'),
      provider,
    })
}

export async function deploy(owner: `0x${string}`, mid: string, expiration: number): Promise<void> {
    logger.log(`deploy(${mid}, ${expiration})`)
    const hexDeploymentId = stringToHex(mid)
    const rawAddress = u8aToHex(u8aConcat(hexToU8a(owner), stringToU8a('@evm_address')))

    // @ts-ignore
    const { output } = await contract.q.getWorkers({ args: [rawAddress] })
    logger.log('output', output.toJSON())
    // assert(output.isOk)
    if (output.asOk.isErr && output.asOk.asErr.toString() == 'UserNotExists') {
        // New deployment
        // @ts-ignore
        await contract.exec.createUser({ args: [rawAddress, hexDeploymentId, expiration] })
    } else {
        // @ts-ignore
        await contract.exec.appendWorker({ args: [rawAddress, hexDeploymentId, expiration] })
    }
}

export async function checkMinerDeployed(mid: string): Promise<[boolean, string | undefined]> {
    logger.log(`checkMinerDeployed(${mid})`)
    const hexDeploymentId = stringToHex(mid)

    // @ts-ignore
    const { output } = await contract.q.getWorkerInfo({ args: [hexDeploymentId] })
    if (output.isErr || output.asOk.isErr) {
        logger.log('PC.getWorkerInfo:', output.toJSON())
        return [false, '']
    }
    const workerInfo = output.asOk.asOk
    const address = workerInfo.instance.inner.accountId
    return [true, `phala://${address.toHex()}`]
}

async function connectDmailWorker(caller: `0x${string}`, mid: string): Promise<PinkContractPromise> {
    const hexDeploymentId = stringToHex(mid)

    // @ts-ignore
    const { output } = await contract.q.getWorkerInfo({ args: [hexDeploymentId] })
    if (output.isErr || output.asOk.isErr) {
        console.log(output.toJSON())
        return
    }
    const workerInfo = output.asOk.asOk
    const address = workerInfo.instance.inner.accountId

    const keyring = new Keyring({ type: 'sr25519', ss58Format: 30 });
    const key = keyring.addFromSeed(hexToU8a(caller));
    const provider = await KeyringPairProvider.create(api, key)

    return getContract({
        client,
        contractId: address,
        abi: readAbi('./src/chain/dmailWorker.json'),
        provider,
    })
}

export async function senderGetKey(mid: string, sender_sk: `0x${string}`, receiver_pk: `0x${string}`, nonce: number): Promise<Uint8Array> {
    const worker = await connectDmailWorker(sender_sk, mid)

    const { output } = await worker.q.senderGetKey({ args: [nonce, receiver_pk] })
    // @ts-ignore
    if (output.isErr || output.asOk.isErr) {
        logger.log(output.toJSON())
        return
    }
    logger.log(output.toJSON())
    // @ts-ignore
    return output.asOk.asOk
}

export async function receiverGetKey(mid: string, receiver_sk: `0x${string}`, sender_pk: `0x${string}`, nonce: number): Promise<Uint8Array> {
    const worker = await connectDmailWorker(receiver_sk, mid)

    const { output } = await worker.q.receiverGetKey({ args: [nonce, sender_pk] })
    // @ts-ignore
    if (output.isErr || output.asOk.isErr) {
        logger.log(output.toJSON())
        return
    }
    logger.log(output.toJSON())
    // @ts-ignore
    return output.asOk.asOk
}
