import SwiftUI

extension View {
    func roundedBorder() -> some View {
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        ).textFieldStyle(.roundedBorder)
    }
    
    func buttonStyle() -> some View {
        return self.padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

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
struct ContentView_CustomTemplateView: View {
    @StateObject private var customInterstitialVM = CTCustomInterstitialViewModel()
    private let customInterstitialPresenter = CTCustomInterstitialPresenter.shared
    
    var body: some View {
        ZStack {
            VStack {
                Button("Show Custom Interstitial") {
                    customInterstitialPresenter.showInterstitial(title: CustomInterstitialTemplate.Constants.title, message: CustomInterstitialTemplate.Constants.message, image: UIImage(named: CustomInterstitialTemplate.Constants.image), confirmAction: nil, cancelAction: nil)
                }
            }
            CustomInterstitialView(viewModel: customInterstitialVM)
        }.onAppear {
            customInterstitialPresenter.interstitialViewModel = customInterstitialVM
        }
    }
}

struct ContentView_CustomTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_CustomTemplateView()
    }
}
#endif
