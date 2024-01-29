import * as db from './db'
import { sleep } from './utils'
import { StateMachine, Task, newTask, updateTask } from './states'

const stateMachine: StateMachine = {
    states: ['Undeployed', 'Deployed', 'Reported'],
    actions: {
        Undeployed: {
            to: 'Deployed',
            async action(context) {
                // PC deploy
            },
            async check(context) {
                // PC getDeployment
                return false
            },
            timeout: 20_000,
        },
        Deployed: {
            to: 'Reported',
            async action(context) {
                // EVM reportOnline
            },
            async check(context) {
                // EVM miners().status == deployed
                return false
            },
            timeout: 60_000,
        }
    }
}

async function syncNewTasks() {
    console.log('syncNewTasks')
    // for each Undeployed miners in EVM.miners()
    //   if miner not in db
    //     task = newTask(..., stateMachine)
    //     db.put(task.id, task)
}

async function refreshTasks() {
    console.log('refreshTasks')
    // for each unstopped task in db
    //   updateTask(task, stateMachine)
    //   db.put(task.id, task)
}

async function main() {
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
