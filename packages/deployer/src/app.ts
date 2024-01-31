import 'dotenv/config'
import * as db from './db'
import { sleep, logger } from './utils'
import { StateMachine, Task, newTask, updateTask } from './states'

import * as PC from './chain/pc'
import * as EVM from './chain/evm'

type Context = {
    owner: `0x${string}`,
    mid: `0x${string}`,
    expiration: number,
    uri?: string,
}

const stateMachine: StateMachine = {
    states: ['Undeployed', 'Deployed', 'Reported'],
    actions: {
        Undeployed: {
            to: 'Deployed',
            async action(context: Context) {
                logger.log('PC.deploy()...')
                await PC.deploy(context.owner, context.mid, context.expiration)
            },
            async check(context: Context) {
                logger.log(`PC.getDeployment(${context.mid})...`)
                const [result, uri] = await PC.checkMinerDeployed(context.mid)
                if (result) {
                    context.uri = uri
                }
                return result
            },
            timeout: 20_000,
        },
        Deployed: {
            to: 'Reported',
            async action(context: Context) {
                await EVM.reportOnline(context.mid, context.uri!)
            },
            async check(context: Context) {
                await EVM.checkMinerDeployed(context.mid)
                return false
            },
            timeout: 60_000,
        }
    }
}

function taskName(id: string): string {
    return `task-${id}`
}

async function syncNewTasks() {
    console.log('syncNewTasks')
    const allMiners = await EVM.getAllMiners();
    for (const miner of allMiners) {
        if (miner.state == 'Undeployed') {
            if (db.get(taskName(miner.mid)) == undefined) {
                const context: Context = {
                    owner: miner.owner,
                    mid: miner.mid,
                    expiration: miner.expiration,
                }
                const task = await newTask(miner.mid, 'Undeployed', context, stateMachine)
                db.put(taskName(miner.mid), task)
            }
        }
    }
}

async function refreshTasks() {
    console.log('refreshTasks')
    for (const [key, value] of db.getAll()) {
        if (!key.startsWith('task-')) {
            continue
        }
        const task = value as Task
        if (!task.stopped) {
            await updateTask(task, stateMachine)
            db.put(key, task)
        }
    }
}

async function main() {
    await PC.connect()
    while(true) {
        await syncNewTasks()
        await refreshTasks()

        await sleep(1000)
    }
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
