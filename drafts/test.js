const {
    isMainThread,
    parentPort,
    workerData,
    threadId,
    MessageChannel,
    MessagePort,
    Worker
} = require('worker_threads');

function mainThread() {
    for (let i = 0; i < 5; i++) {
        const worker = new Worker(__filename, { workerData: i });
        worker.on('exit', code => { console.log(`main: worker stopped with exit code ${code}`); });
        worker.on('message', msg => {
            console.log(`main: receive ${msg}`);
            worker.postMessage(msg + 1);
        });
    }
}

function workerThread() {
    console.log(`worker: workerData ${workerData}`);
    parentPort.on('message', msg => {
        console.log(`worker: receive ${msg}`);
    });
    parentPort.postMessage(workerData);
}

if (isMainThread) {
    mainThread();
} else {
    workerThread();
}