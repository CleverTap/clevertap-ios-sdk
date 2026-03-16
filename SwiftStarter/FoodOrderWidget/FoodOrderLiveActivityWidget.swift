import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Food Order Live Activity Widget

@available(iOS 16.2, *)
struct FoodOrderLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodOrderActivityAttributes.self) { context in
            // Lock Screen / Notification Banner UI
            FoodOrderLockScreenView(
                attributes: context.attributes,
                state: context.state
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view (long-press on Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: progressIcon(context.state.progressStep))
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ETA")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.estimatedDelivery, style: .timer)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.primary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.restaurantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.status)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ProgressView(value: Double(context.state.progressStep), total: 3.0)
                            .tint(.orange)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.estimatedDelivery, style: .timer)
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.orange)
            }
            .widgetURL(URL(string: "swiftstarter://liveactivity?tag=food-order-\(context.attributes.orderId)&type=FoodOrderActivityAttributes"))
            .keylineTint(.orange)
        }
    }

    private func progressIcon(_ step: Int) -> String {
        switch step {
        case 0: return "checkmark.circle.fill"
        case 1: return "flame.fill"
        case 2: return "bicycle"
        case 3: return "house.fill"
        default: return "clock.fill"
        }
    }
}

// MARK: - Lock Screen / Banner View

@available(iOS 16.2, *)
struct FoodOrderLockScreenView: View {
    let attributes: FoodOrderActivityAttributes
    let state: FoodOrderActivityAttributes.ContentState

    private let steps = ["Placed", "Preparing", "En Route", "Delivered"]

    var body: some View {
        VStack(spacing: 10) {
            // Header row: restaurant + ETA timer
            HStack(alignment: .top) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.restaurantName)
                        .font(.headline)
                    Text(attributes.orderSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("ETA")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(state.estimatedDelivery, style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
            }

            // Status message
            Text(state.status)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Progress steps
            HStack(spacing: 0) {
                ForEach(0 ..< steps.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(index <= state.progressStep
                                      ? Color.orange
                                      : Color.secondary.opacity(0.25))
                                .frame(width: 12, height: 12)
                            if index <= state.progressStep {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        Text(steps[index])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(index <= state.progressStep
                                             ? .primary : .secondary)
                    }
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < state.progressStep
                                  ? Color.orange : Color.secondary.opacity(0.25))
                            .frame(height: 2)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
    }
}
