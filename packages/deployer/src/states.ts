import { logger } from "./utils"

export type ActionFn = (context: any) => Promise<void>
export type CheckFn = (context: any) => Promise<boolean>
export type Action = {
    to: string,
    action: ActionFn,
    check: CheckFn,
    timeout: number,
}
export type StateMachine = {
    states: string[],
    actions: {
        [state: string]: Action,
    }
}
export type Task = {
    name: string,
    state: string,
    startedAt: number,
    context: any,
    stopped: boolean,
}

// Trigger the action associated with the task. Mark "stopped" if there's no further action.
async function onEnterState(task: Task, stateMachine: StateMachine): Promise<void> {
    const currentAction = stateMachine.actions[task.state]
    if (currentAction == undefined) {
        logger.log(`Task(${task.name}): finished`)
        task.stopped = true
        return
    }
    await currentAction.action(task.context)
}

export async function newTask(name: string, initialState: string, context: any, stateMachine: StateMachine): Promise<Task> {
    logger.log(`Task(${name}): ${initialState} started`)
    const task: Task = {
        name,
        state: initialState,
        startedAt: Date.now(),
        context,
        stopped: false,
    }
    await onEnterState(task, stateMachine)
    return task
}

export async function updateTask(task: Task, stateMachine: StateMachine) {
    const currentAction = stateMachine.actions[task.state]
    if (currentAction == undefined) {
        logger.log(`Task(${task.name}): finished`)
        task.stopped = true
        return
    }
    // finished, move on
    if (await currentAction.check(task.context)) {
        logger.log(`Task(${task.name}): ${task.state} -> ${currentAction.to}`)
        const now = Date.now()
        task.startedAt = now
        task.state = currentAction.to
        await onEnterState(task, stateMachine)
        return
    }
    // expired?
    const now = Date.now()
    if (now > task.startedAt + currentAction.timeout) {
        logger.log(`Task(${task.name}): ${task.state} retrying`)
        // expired; retry!
        task.startedAt = now
        await onEnterState(task, stateMachine)
        return
    }
    // just wait patiently
}