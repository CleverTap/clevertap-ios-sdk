import SwiftUI

struct CustomInterstitialView: View {
    @ObservedObject var viewModel: CTCustomInterstitialViewModel
    
    var body: some View {
        if viewModel.isVisible {
            VStack(spacing: 20) {
                Text(viewModel.title)
                    .font(.headline)
                
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .clipShape(Rectangle())
                }
                
                ScrollView {
                    VStack {
                        Text(viewModel.message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }.frame(maxHeight: .infinity)
                }
                
                HStack {
                    if viewModel.showCloseButton {
                        Button(action: {
                            if let cancel = viewModel.cancelAction {
                                cancel()
                            } else {
                                viewModel.isVisible = false
                            }
                        }) {
                            Text("Close")
                                .buttonStyle()
                        }
                    }
                    
                    Button(action: {
                        if let confirm = viewModel.confirmAction {
                            confirm()
                        } else {
                            viewModel.isVisible = false
                        }
                    }) {
                        Text("Confirm")
                            .buttonStyle()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
        }
    }
}

#if DEBUG
struct ContentView_CustomInterstitialView: View {
    @StateObject private var customInterstitialVM = CTCustomInterstitialViewModel()
    private let customInterstitialPresenter = CTCustomInterstitialPresenter.shared
    
    var body: some View {
        ZStack {
            VStack {
                Button("Show Custom Interstitial") {
                    customInterstitialPresenter.show(title: CustomInterstitialTemplate.DefaultValues.title, message: CustomInterstitialTemplate.DefaultValues.message, image: UIImage(named: CustomInterstitialTemplate.DefaultValues.image), confirmAction: nil, cancelAction: nil)
                }
            }
            CustomInterstitialView(viewModel: customInterstitialVM)
        }.onAppear {
            customInterstitialPresenter.viewModel = customInterstitialVM
        }
    }
}

struct ContentView_CustomInterstitialView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_CustomInterstitialView()
    }
}
#endif
