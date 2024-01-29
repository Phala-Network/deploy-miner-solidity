import { logger } from "../utils"
// const KEY = process.env.PC_PRIVKEY

export async function deploy(mid: string, expiration: number): Promise<void> {
    logger.log(`deploy(${mid}, ${expiration})`);
    // TODO: contract.deploy(mid, expiration)
}

export async function checkMinerDeployed(mid: string): Promise<boolean> {
    logger.log(`checkMinerDeployed(${mid})`);
    // TODO: await contract.getDeployment(mid).isOk
    return false
}
