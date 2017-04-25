#!/usr/bin/env swift

// FIXME Shebang line doesn't work with local imports
//       Use 'likeness' script in root dir for the same effect

import Foundation

let inputs = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]

// A dumb random-sleeper work function for illustrative purposes
func randomSleep(_ input: String) -> (String) {
    let sleepTime = UInt32(random(500000))
    print("Worker '\(input)' sleeping \(sleepTime)")
    usleep(sleepTime)
    print("Worker '\(input)' complete")
    return input;
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
