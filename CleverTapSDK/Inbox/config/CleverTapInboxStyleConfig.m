#import "CleverTap+Inbox.h"

@implementation CleverTapInboxStyleConfig

- (instancetype)copyWithZone:(NSZone*)zone {
    CleverTapInboxStyleConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.title = self.title;
    copy.backgroundColor = self.backgroundColor;
    copy.cellBackgroundColor = self.cellBackgroundColor;
    copy.messageTags = self.messageTags;
    copy.navigationBarTintColor = self.navigationBarTintColor;
    copy.navigationTintColor = self.navigationTintColor;
    copy.tabUnSelectedTextColor = self.tabUnSelectedTextColor;
    copy.tabSelectedTextColor = self.tabSelectedTextColor;
    copy.tabSelectedBgColor = self.tabSelectedBgColor;
    copy.tabBackgroundColor = self.tabBackgroundColor;
    return copy;
}

@end
