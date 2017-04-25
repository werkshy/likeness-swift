#!/usr/bin/swift

//
//  work.swift
//  
//
//  Created by Andy O'Neill on 4/20/17.
//
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

import Dispatch

let inputs = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]

// Our dumb random-sleeper work function
func randomSleep(_ input: String) -> (String) {
    let sleepTime = randomInt32(500000)
    print("Worker '\(input)' sleeping \(sleepTime)")
    usleep(sleepTime)
    print("Worker '\(input)' complete")
    return input;
}

// Random helper function (seems like Darwin and Linux have different options)
func randomInt32(_ max: Int) -> UInt32 {
#if os(Linux)
    return UInt32(random() % max)
#else
    return arc4random_uniform(max)
#endif
}


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

// Define a pool that will have return type of String
let pool = WorkerPool<String>()


// Build a list of tasks (closures that return String)
let tasks = inputs.map { (value: String) -> (() -> String) in
    return { randomSleep(value) }
}

// Feed the tasks to the worker pool
pool.go(tasks)

// Wait and retrieve results
let results = pool.getResults()
print("\(results.count) results: \(results)")

print("All done")



