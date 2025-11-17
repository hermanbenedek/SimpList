import WidgetKit
import SwiftUI

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
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    func loadTodos() -> [TodoEntry] {
        let sharedDefaults = UserDefaults(suiteName: "group.com.voovo.simplist")
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

struct TodoEntry {
    let text: String
    let isDone: Bool
}

struct SimpListWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SimpList")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)

            if entry.todos.isEmpty {
                Text("No todos yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ForEach(Array(entry.todos.prefix(5).enumerated()), id: \.offset) { index, todo in
                    HStack(alignment: .top, spacing: 8) {
                        Text(todo.text)
                            .font(.body)
                            .foregroundColor(todo.isDone ? .secondary : .primary)
                            .strikethrough(todo.isDone)
                            .lineLimit(2)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}

struct SimpListWidget: Widget {
    let kind: String = "SimpListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SimpListWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SimpList")
        .description("View your todo list")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SimpListWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimpListWidget()
    }
}
