#import "CleverTap+Inbox.h"

@implementation CleverTapInboxStyleConfig

- (instancetype)copyWithZone:(NSZone*)zone {
    CleverTapInboxStyleConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.backgroundColor = self.backgroundColor;
    copy.cellBackgroundColor = self.cellBackgroundColor;
    copy.cellBorderColor = self.cellBorderColor;
    copy.contentBackgroundColor = self.contentBackgroundColor;
    copy.contentBorderColor = self.contentBorderColor;
    copy.messageTitleColor = self.messageTitleColor;
    copy.messageBodyColor = self.messageBodyColor;
    copy.messageTags = self.messageTags;
    return copy;
}

@end
