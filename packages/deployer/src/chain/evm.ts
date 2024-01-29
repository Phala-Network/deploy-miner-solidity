// const KEY = process.env.EVM_PRIVKEY

export type Miner = {
    mid: string,
    state: 'Undeployed' | 'Deployed' | 'Expired',
    expiration: number,
}

export async function getAllMiners(): Promise<Miner[]> {
    // TODO: contract.miners.entries()
    return [{
        mid: '0xDEADBEEF',
        state: 'Undeployed',
        expiration: 123456,
    }]
}

export async function reportOnline(mid: string): Promise<void> {
    // TODO: await contract.reportOnline(mid)
}

export async function checkMinerDeployed(mid: string): Promise<boolean> {
    // TODO: contract.miners(mid).state == 'Deployed'
    return false
}
