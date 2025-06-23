//
//  NativeDisplayUIView.swift
//  SwiftUIStarter
//
//  Created by CleverTap on 23/06/25.
//

import SwiftUI
import CleverTapSDK

struct NativeDisplayUIView: View {
    @StateObject private var viewModel = NativeDisplayUIViewModel()
    @State private var displayUnitID = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        Text("NATIVE DISPLAY\nNOTE: CLICKING ON BELOW BUTTON WILL RECORD EVENT WITH SAME NAME.")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Display type buttons
                    HStack(spacing: 20) {
                        Button("ND_Simple") {
                            viewModel.handleDisplayType(.simple)
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                        
                        Button("ND_Carousel") {
                            viewModel.handleDisplayType(.carousel)
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    
                    // Display unit ID input and Get Unit button
                    HStack(spacing: 12) {
                        TextField("Display unit ID", text: $displayUnitID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Get Unit") {
                            viewModel.getDisplayUnit(withID: displayUnitID)
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    
                    // Get all display units button
                    Button("Get all display units") {
                        viewModel.getAllDisplayUnits()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    
                    Divider()
                        .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
                
                // Display units list
                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Text("ALL DISPLAY UNITS")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(Color(.systemGroupedBackground))
                    
                    // Display units list
                    List {
                        ForEach(viewModel.displayUnits.indices, id: \.self) { index in
                            let displayUnit = viewModel.displayUnits[index]
                            DisplayUnitRowView(
                                displayUnit: displayUnit,
                                onClick: {
                                    viewModel.handleClick(displayUnit)
                                },
                                onView: {
                                    viewModel.handleView(displayUnit)
                                },
                                onShowDetails: {
                                    showAlert(title: "Display Unit Details", message: getDisplayUnitDetails(displayUnit))
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Native Display")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setupCleverTap()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func getDisplayUnitDetails(_ displayUnit: CleverTapDisplayUnit) -> String {
        guard let contentArray = displayUnit.contents,
              let content = contentArray.first else {
            return "No content available"
        }
        
        var kvPairs = ""
        if let ce = displayUnit.customExtras {
            kvPairs = String(describing: ce)
        }
        
        let title = content.title ?? "No Title"
        let message = content.message ?? "No Message"
        let imageURL = content.mediaUrl ?? "No Image URL"
        let actionURL = content.actionUrl ?? "No Action URL"
        
        return """
        Title: \(title)
        Message: \(message)
        CustomKeyValue: \(kvPairs)
        Action URL: \(actionURL)
        Image URL: \(imageURL)
        """
    }
}

// MARK: - Display Unit Row View
struct DisplayUnitRowView: View {
    let displayUnit: CleverTapDisplayUnit
    let onClick: () -> Void
    let onView: () -> Void
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(displayUnit.unitID ?? "Display unit ID")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Click") {
                    onClick()
                }
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .buttonStyle(PlainButtonStyle())
                
                Button("View") {
                    onView()
                }
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .buttonStyle(PlainButtonStyle())
                
                Button("Show Details") {
                    onShowDetails()
                }
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct NativeDisplayUIView_Previews: PreviewProvider {
    static var previews: some View {
        NativeDisplayUIView()
    }
}
