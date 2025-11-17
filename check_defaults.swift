#!/usr/bin/env swift
import Foundation

let sharedDefaults = UserDefaults(suiteName: "group.com.simplist.app")

print("=== Checking Shared UserDefaults ===")
print("Suite Name: group.com.simplist.app")
print("")

if let allKeys = sharedDefaults?.dictionaryRepresentation().keys.sorted() {
    print("All keys found:")
    for key in allKeys {
        let value = sharedDefaults?.string(forKey: key) ?? sharedDefaults?.object(forKey: key) as? String ?? "unable to read"
        print("  - \(key): \(value)")
    }
} else {
    print("No keys found or unable to access app group")
}

print("")
print("Checking specific keys:")
if let todos = sharedDefaults?.string(forKey: "HomeWidget.todos") {
    print("  HomeWidget.todos: \(todos)")
} else {
    print("  HomeWidget.todos: NOT FOUND")
}

if let todos = sharedDefaults?.string(forKey: "todos") {
    print("  todos: \(todos)")
} else {
    print("  todos: NOT FOUND")
}
