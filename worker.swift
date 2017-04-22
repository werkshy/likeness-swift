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

let inputs = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]

func work(_ input: String) -> (String) {
    // TODO add random sleep
    let sleepTime = randomInt32(max: 10000)
    print("Worker '\(input)' sleeping \(sleepTime)")
    usleep(sleepTime)
    return input;
}

func randomInt32(max: Int) -> UInt32 {
#if os(Linux)
    return UInt32(random() % max)
#else
    return arc4random_uniform(max)
#endif
}

let concurrentQueue = DispatchQueue(label: "concurrentQueue", qos: .utility, attributes: .concurrent)
let serialQueue = DispatchQueue(label: "serialQueue")
let maxConcurrency = 2
let semaphore = DispatchSemaphore(value: maxConcurrency)
let group = DispatchGroup()

for input in inputs {
    serialQueue.async {
        semaphore.wait()

        concurrentQueue.async(group: group) {
            let result = work(input)
            print("Got result: " + result)
            semaphore.signal()
        }
    }
}

print("Finished queuing")

group.wait()

print ("Group finished")
