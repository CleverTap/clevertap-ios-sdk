#import "CTInboxBaseMessageCell.h"
#import "CTInboxMessageActionView.h"

@interface CTInboxIconMessageCell : CTInboxBaseMessageCell <CTInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *cellIcon;

@end
