import { parseAbi, getContract } from 'viem'
import { createPublicClient, createWalletClient, http, numberToHex } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { foundry } from 'viem/chains'
 
// import { publicClient, walletClient } from './client'

const KEY = <`0x${string}`> process.env.EVM_PRIVKEY || '0x01'
const CONTRACT = <`0x${string}`> process.env.EVM_CONTRACT || '0xFBA3912Ca04dd458c843e2EE08967fC04f3579c2'

const abi = parseAbi([
    'struct MinerInfo { address owner; uint256 expiration; uint256 state; }',
    'function miners(bytes32 minerId) view returns (MinerInfo)',
    'function getAllMiners() public view returns (MinerInfo[] memory)',
    'function reportMinerOnline(bytes32 minerId) external',
    'function reportMinerOffline(bytes32 minerId) external',
])

const account = privateKeyToAccount(KEY)
const publicClient = createPublicClient({
    chain: foundry,
    transport: http(),
})
const walletClient = createWalletClient({
    account,
    chain: foundry,
    transport: http()
})

// const contract = getContract({
//   address: '0xFBA3912Ca04dd458c843e2EE08967fC04f3579c2',
//   abi,
//   client: walletClient,
// })

export type Miner = {
    mid: `0x${string}`,
    state: 'Undeployed' | 'Deployed' | 'Expired',
    expiration: number,
}
const states = ['Undeployed', 'Deployed', 'Expired'];

export async function getAllMiners(): Promise<Miner[]> {
    const result = await publicClient.readContract({
        address: CONTRACT,
        abi,
        functionName: 'getAllMiners',
    });
    return result.map((r, idx) => (<Miner> {
        mid: numberToHex(idx, {size: 32}),
        state: states[Number(r.state)],
        expiration: Number(r.expiration),
    }))
}

export async function reportOnline(mid: `0x${string}`): Promise<void> {
    const { request } = await publicClient.simulateContract({
        account: account.address,
        address: CONTRACT,
        abi,
        functionName: 'reportMinerOnline',
        args: [mid],
    })
    await walletClient.writeContract(request);
}

export async function checkMinerDeployed(mid: `0x${string}`): Promise<boolean> {
    const result = await publicClient.readContract({
        address: CONTRACT,
        abi,
        functionName: 'miners',
        args: [mid]
    })
    return result.state == 1n
}
