import WidgetKit
import SwiftUI

@main
struct FoodOrderWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            FoodOrderLiveActivityWidget()
        }
    }
}
