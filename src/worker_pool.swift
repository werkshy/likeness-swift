
// WorkerPool - a limited-concurrency worker pool. Each task (closure) passed in
// is run and the return values can be retrieved with getResults().
//
// The type parameter T is the type of the return values.
//
// Example Usage
//
// 

import Dispatch
import Foundation

class WorkerPool<T> {
    var results : Array<T> = Array<T>()

    // Serial queue that uses the semaphore to throttle how much concurrency we
    // have in the concurrent queue.
    let serialQueue = DispatchQueue(label: "serialQueue")
    // Semaphore that is used to provide the throttling
    let semaphore : DispatchSemaphore

    // Concurrent queue where we actually run our tasks
    let concurrentQueue = DispatchQueue(
        label: "concurrentQueue",
        qos: .utility,
        attributes: .concurrent
    )

    // Queue to synchronize access to our results array
    let resultsManipulatorQueue = DispatchQueue(label: "resultsQueue")

    // group we can use to tell when all our background tasks are done.
    let group = DispatchGroup()

    init(maxConcurrency: Int = 4) {
        self.semaphore = DispatchSemaphore(value: maxConcurrency)
    }

    // run a list of tasks (closures that return type T) in the background
    func go(_ tasks : Array< () -> T >) {
        for task in tasks {
            serialQueue.async(group: group) {
                self.semaphore.wait() // wait until there is a free semaphore

                self.concurrentQueue.async(group: self.group) {
                    let result = task()
                    self.addResult(result)
                    self.semaphore.signal() // release our semaphore
                }
            }
        }
        print("Finished queuing")
    }


    // Wait for all jobs to finish and return the array
    func getResults() -> Array<T> {
        wait()
        return resultsManipulatorQueue.sync {
            return self.results
        }
    }

    // Append a result to the results queue in a threadsafe manner.
    func addResult(_ result: T) {
        resultsManipulatorQueue.async {
            self.results.append(result)
        }
    }

    func wait() {
        self.group.wait()
    }
}




