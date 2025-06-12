import SwiftUI

struct CTOpenURLConfirmView: View {
    @ObservedObject var viewModel: CTOpenURLConfirmViewModel
    
    var body: some View {
        if viewModel.isVisible {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    Text("Open URL")
                        .font(.headline)
                    
                    ScrollView {
                        VStack {
                            Text("Do you want to navigate to \"\(viewModel.displayURL)\"?")
                                .font(.body)
                                .padding(.horizontal)
                        }.frame(maxHeight: .infinity)
                    }
                    
                    HStack {
                        Button(action: {
                            viewModel.executeCancelAction()
                        }) {
                            Text("No")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: {
                            viewModel.executeConfirmAction()
                        }) {
                            Text("Yes")
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
                .padding(.vertical, geometry.size.height * 0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
            }
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
                Button("Show \(CTOpenURLConfirmTemplate.name)") {
                    openURLConfirmPresenter.show(url: "https://clevertap.com/", confirmAction: nil, cancelAction: nil)
                }
            }
            CTOpenURLConfirmView(viewModel: openURLConfirmVM)
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
