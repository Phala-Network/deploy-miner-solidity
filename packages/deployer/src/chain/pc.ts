// import { ContractFunctionExecutionError } from "viem";
import { logger } from "../utils"
import fs from 'fs'
import { ApiPromise, WsProvider } from '@polkadot/api';
import { OnChainRegistry, getClient, getContract, KeyringPairProvider, AbiLike } from '@phala/sdk'

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

    const wsApiProvider = new WsProvider('wss://poc6.phala.network/ws');
    const api = await ApiPromise.create({ provider: wsApiProvider });
    const provider = await KeyringPairProvider.createFromSURI(api, KEY)
    client = await getClient({ transport: 'wss://poc6.phala.network/ws' })
    contract = await getContract({
      client,
      contractId: CONTRACT,
      abi: readAbi(),
      provider,
    })
}

export async function deploy(mid: string, expiration: number): Promise<void> {
    logger.log(`deploy(${mid}, ${expiration})`);

    // contract.send.createUser(accountFromEvm, mid, expirtaion)

    // TODO: contract.deploy(mid, expiration)
}

export async function checkMinerDeployed(mid: string): Promise<[boolean, string | undefined]> {
    logger.log(`checkMinerDeployed(${mid})`);

    // @ts-ignore
    const { output } = await contract.q.getWorkerInfo({ args: [mid] })
    if (output.isErr || output.asOk.isErr) {
        console.log(output.toJSON())
        return [false, '']
    }
    const workerInfo = output.asOk.asOk
    const address = workerInfo.instance.inner.accountId
    return [true, `phala://${address.toHex()}`]
}