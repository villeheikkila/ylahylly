import ClusterMap
import MapKit
import SwiftUI

@main
struct Entrypoint: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            LoadingWrapper {
                StoreMap()
            }
            .environment(appModel)
            .task {
                await appModel.fetchBeerStoreData()
            }
        }
    }
}

struct LoadingWrapper<Content: View>: View {
    @Environment(AppModel.self) private var appModel
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if appModel.isLoading {
            ProgressView()
        } else {
            content()
        }
    }
}
