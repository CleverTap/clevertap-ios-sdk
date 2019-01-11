#import "CTInboxBaseMessageCell.h"
#import "CTInboxMessageActionView.h"

@interface CTInboxIconMessageCell : CTInboxBaseMessageCell <CTInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *cellIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cellIconWidthContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cellIconRatioContraint;

@end
