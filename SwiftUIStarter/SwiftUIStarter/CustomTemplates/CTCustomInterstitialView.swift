import SwiftUI

struct CTCustomInterstitialView: View {
    @ObservedObject var viewModel: CTCustomInterstitialViewModel
    
    var body: some View {
        if viewModel.isVisible {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    Text(viewModel.title)
                        .font(.headline)
                    
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.6)
                            .frame(maxHeight: min(200, geometry.size.height * 0.3))
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
                                viewModel.executeCancelAction()
                            }) {
                                Text("Close")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Button(action: {
                            viewModel.executeConfirmAction()
                        }) {
                            Text("Confirm")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(radius: 20)
                .padding(.horizontal, 40)
                .padding(.vertical, geometry.size.height * 0.1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
            }
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
                Button("Show \(CTCustomInterstitialTemplate.name)") {
                    customInterstitialPresenter.show(configuration: CTInterstitialConfiguration.default, confirmAction: nil, cancelAction: nil)
                }
            }
            CTCustomInterstitialView(viewModel: customInterstitialVM)
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
