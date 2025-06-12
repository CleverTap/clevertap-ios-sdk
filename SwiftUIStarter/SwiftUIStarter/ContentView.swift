import SwiftUI

struct ContentView: View {
    @StateObject private var customInterstitialVM = CTCustomInterstitialViewModel()
    let customInterstitialPresenter = CTCustomInterstitialPresenter.shared
    
    @StateObject private var openURLConfirmVM = CTOpenURLConfirmViewModel()
    private let openURLConfirmPresenter = CTOpenURLConfirmPresenter.shared
    
    var body: some View {
        ZStack {
            HomeScreen()
            CTCustomInterstitialView(viewModel: customInterstitialVM)
            CTOpenURLConfirmView(viewModel: openURLConfirmVM)
        }.onAppear {
            customInterstitialPresenter.viewModel = customInterstitialVM
            openURLConfirmPresenter.viewModel = openURLConfirmVM
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
