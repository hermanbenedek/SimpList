//
//  SimpListWidget.swift
//  SimpListWidget
//
//  Created by Benedek Herman on 2025. 11. 17..
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Intents for Interactivity

@available(iOS 17.0, *)
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"

    @Parameter(title: "Index")
    var index: Int

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: "group.com.simplist.app")
        guard let todosJson = sharedDefaults?.string(forKey: "todos"),
              let data = todosJson.data(using: .utf8),
              var jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return .result()
        }

        guard index >= 0 && index < jsonArray.count else {
            return .result()
        }

        if var todo = jsonArray[index] as? [String: Any],
           let isDone = todo["isDone"] as? Bool {
            todo["isDone"] = !isDone
            jsonArray[index] = todo

            if let updatedData = try? JSONSerialization.data(withJSONObject: jsonArray),
               let updatedJson = String(data: updatedData, encoding: .utf8) {
                sharedDefaults?.set(updatedJson, forKey: "todos")
                sharedDefaults?.synchronize()
            }
        }

        return .result()
    }
}

@available(iOS 17.0, *)
struct DeleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Todo"

    @Parameter(title: "Index")
    var index: Int

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: "group.com.simplist.app")
        guard let todosJson = sharedDefaults?.string(forKey: "todos"),
              let data = todosJson.data(using: .utf8),
              var jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return .result()
        }

        guard index >= 0 && index < jsonArray.count else {
            return .result()
        }

        jsonArray.remove(at: index)

        if let updatedData = try? JSONSerialization.data(withJSONObject: jsonArray),
           let updatedJson = String(data: updatedData, encoding: .utf8) {
            sharedDefaults?.set(updatedJson, forKey: "todos")
            sharedDefaults?.synchronize()
        }

        return .result()
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todos: [
            TodoEntry(text: "Sample Todo 1", isDone: false),
            TodoEntry(text: "Sample Todo 2", isDone: true)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todos: loadTodos())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, todos: loadTodos())
        // Update every 5 minutes to keep widget fresh
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadTodos() -> [TodoEntry] {
        let sharedDefaults = UserDefaults(suiteName: "group.com.simplist.app")
        guard let todosJson = sharedDefaults?.string(forKey: "todos"),
              let data = todosJson.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return jsonArray.compactMap { dict in
            guard let text = dict["text"] as? String,
                  let isDone = dict["isDone"] as? Bool else {
                return nil
            }
            return TodoEntry(text: text, isDone: isDone)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todos: [TodoEntry]
}

struct TodoEntry: Identifiable {
    let id = UUID()
    let text: String
    let isDone: Bool
}

// MARK: - Widget View

struct SimpListWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.todos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No todos yet")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(entry.todos.prefix(maxItems).enumerated()), id: \.element.id) { index, todo in
                        if #available(iOS 17.0, *) {
                            HStack(spacing: 0) {
                                Button(intent: ToggleTodoIntent(index: index)) {
                                    TodoRowView(todo: todo)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(intent: DeleteTodoIntent(index: index)) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red.opacity(0.7))
                                        .padding(.leading, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            TodoRowView(todo: todo)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var maxItems: Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 5
        case .systemLarge:
            return 10
        case .systemExtraLarge:
            return 15
        default:
            return 5
        }
    }
}

struct TodoRowView: View {
    let todo: TodoEntry

    var body: some View {
        Text(todo.text.isEmpty ? "Empty todo" : todo.text)
            .font(.system(size: 26, weight: .medium))
            .foregroundColor(todo.isDone ? .gray : .black)
            .strikethrough(todo.isDone, color: .gray)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(todo.isDone ? 0.5 : 1.0)
    }
}

// MARK: - Widget Configuration

struct SimpListWidget: Widget {
    let kind: String = "SimpListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SimpListWidgetEntryView(entry: entry)
                    .containerBackground(.white, for: .widget)
            } else {
                SimpListWidgetEntryView(entry: entry)
                    .background(Color.white)
            }
        }
        .configurationDisplayName("SimpList")
        .description("View and manage your todo list")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

#Preview(as: .systemSmall) {
    SimpListWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoEntry(text: "Buy groceries", isDone: false),
        TodoEntry(text: "Call mom", isDone: true),
        TodoEntry(text: "Finish project", isDone: false)
    ])
}

#Preview(as: .systemMedium) {
    SimpListWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoEntry(text: "Buy groceries", isDone: false),
        TodoEntry(text: "Call mom", isDone: true),
        TodoEntry(text: "Finish project", isDone: false),
        TodoEntry(text: "Walk the dog", isDone: false),
        TodoEntry(text: "Read a book", isDone: true)
    ])
}

#Preview(as: .systemLarge) {
    SimpListWidget()
} timeline: {
    SimpleEntry(date: .now, todos: [
        TodoEntry(text: "Buy groceries", isDone: false),
        TodoEntry(text: "Call mom", isDone: true),
        TodoEntry(text: "Finish project", isDone: false),
        TodoEntry(text: "Walk the dog", isDone: false),
        TodoEntry(text: "Read a book", isDone: true),
        TodoEntry(text: "Clean the house", isDone: false),
        TodoEntry(text: "Send emails", isDone: true),
        TodoEntry(text: "Exercise", isDone: false)
    ])
}
