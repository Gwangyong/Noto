//
//  ContentView.swift
//  Noto
//
//  Created by 서광용 on 6/13/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  // NotoApp에서 주입받은 컨테이너를 꺼내 씀
    @Environment(\.modelContext) private var modelContext
  // @Query: 데이터베이스에게 데이터를 요청하는 명령
  // Item 테이블의 데이터를 전부 가져오고, 데이터가 바뀌면 자동으로 갱신
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }

            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
