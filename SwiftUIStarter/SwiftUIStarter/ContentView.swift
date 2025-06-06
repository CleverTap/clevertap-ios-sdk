import SwiftUI

struct ContentView: View {
    @StateObject private var customInterstitialVM = CTCustomInterstitialViewModel()
    let customInterstitialPresenter = CTCustomInterstitialPresenter.shared
    
    var body: some View {
        ZStack {
            HomeScreen()
            CustomInterstitialView(viewModel: customInterstitialVM)
        }.onAppear {
            customInterstitialPresenter.interstitialViewModel = customInterstitialVM
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
