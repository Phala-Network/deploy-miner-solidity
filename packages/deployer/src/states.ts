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

export async function newTask(name: string, initialState: string, context: any, stateMachine: StateMachine): Promise<Task> {
    const currentAction = stateMachine.actions[initialState]
    console.log(`Task(${name}): ${initialState} started`)
    await currentAction.action(context);
    return {
        name,
        state: initialState,
        startedAt: Date.now(),
        context,
        stopped: false,
    }
}

export async function updateTask(task: Task, stateMachine: StateMachine) {
    const currentAction = stateMachine.actions[task.state]
    if (currentAction == undefined) {
        console.log(`Task(${task.name}): finished`)
        task.stopped = true
        return
    }
    // finished, move on
    if (await currentAction.check(task.context)) {
        console.log(`Task(${task.name}): ${task.state} -> ${currentAction.to}`)
        const now = Date.now()
        task.startedAt = now
        task.state = currentAction.to
        const nextAction = stateMachine.actions[currentAction.to]
        await nextAction.action(task.context)
        return
    }
    // expired?
    const now = Date.now()
    if (now > task.startedAt + currentAction.timeout) {
        console.log(`Task(${task.name}): ${task.state} retrying`)
        // expired; retry!
        task.startedAt = now
        await currentAction.action(task.context)
        return
    }
    // just wait patiently
}