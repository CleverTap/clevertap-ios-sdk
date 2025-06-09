import SwiftUI

struct OpenURLConfirmView: View {
    @ObservedObject var viewModel: CTOpenURLConfirmViewModel
    
    var body: some View {
        if viewModel.isVisible {
            VStack(spacing: 20) {
                Text("Open URL")
                    .font(.headline)
                
                ScrollView {
                    VStack {
                        Text("Do you want to navigate to \"\(viewModel.url)\"?")
                            .font(.body)
                            .padding(.horizontal)
                    }.frame(maxHeight: .infinity)
                }
                
                HStack {
                    Button(action: {
                        viewModel.executeCancelAction()
                    }) {
                        Text("No")
                            .buttonStyle()
                    }
                    
                    Button(action: {
                        viewModel.executeConfirmAction()
                    }) {
                        Text("Yes")
                            .buttonStyle()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .padding(.vertical, 160)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
        }
    }
}

#if DEBUG
struct ContentView_OpenURLConfirmView: View {
    @StateObject private var openURLConfirmVM = CTOpenURLConfirmViewModel()
    private let openURLConfirmPresenter = CTOpenURLConfirmPresenter.shared
    
    var body: some View {
        ZStack {
            VStack {
                Button("Show Open URL Confirm") {
                    openURLConfirmPresenter.show(url: "https://clevertap.com/", confirmAction: nil, cancelAction: nil)
                }
            }
            OpenURLConfirmView(viewModel: openURLConfirmVM)
        }.onAppear {
            openURLConfirmPresenter.viewModel = openURLConfirmVM
        }
    }
}

struct ContentView_OpenURLConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_OpenURLConfirmView()
    }
}
#endif
