//
//  NotoApp.swift
//  Noto
//
//  Created by 서광용 on 6/13/26.
//

import SwiftUI
import SwiftData

@main
struct NotoApp: App {
  // ModelContainer: SwiftData의 저장소 관리 객체 (큰 저장 환경)
    var sharedModelContainer: ModelContainer = {
      // Schema: 이 앱이 저장할 모델 목록
        let schema = Schema([
          // Item을 저장한다는 뜻. Item 테이블
            Item.self,
        ])
      // ModelConfiguration: 저장 방식을 설정하는 객체
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
      // 컨테이너 주입
    }
}
