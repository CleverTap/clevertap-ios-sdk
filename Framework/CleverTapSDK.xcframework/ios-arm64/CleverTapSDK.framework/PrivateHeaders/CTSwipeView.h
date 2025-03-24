//
//  SwipeView.h
//
//  Version 1.3.2
//
//  Created by Nick Lockwood on 03/09/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version of SwipeView from here:
//
//  https://github.com/nicklockwood/SwipeView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wauto-import"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc) && __has_feature(objc_arc_weak)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, CTSwipeViewAlignment)
{
    CTSwipeViewAlignmentEdge = 0,
    CTSwipeViewAlignmentCenter
};


@protocol CTSwipeViewDataSource, CTSwipeViewDelegate;

@interface CTSwipeView : UIView

@property (nonatomic, weak_delegate) IBOutlet id<CTSwipeViewDataSource> dataSource;
@property (nonatomic, weak_delegate) IBOutlet id<CTSwipeViewDelegate> delegate;
@property (nonatomic, readonly) NSInteger numberOfItems;
@property (nonatomic, readonly) NSInteger numberOfPages;
@property (nonatomic, readonly) CGSize itemSize;
@property (nonatomic, assign) NSInteger itemsPerPage;
@property (nonatomic, assign) BOOL truncateFinalPage;
@property (nonatomic, strong, readonly) NSArray *indexesForVisibleItems;
@property (nonatomic, strong, readonly) NSArray *visibleItemViews;
@property (nonatomic, strong, readonly) UIView *currentItemView;
@property (nonatomic, assign) NSInteger currentItemIndex;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) CTSwipeViewAlignment alignment;
@property (nonatomic, assign) CGFloat scrollOffset;
@property (nonatomic, assign, getter = isPagingEnabled) BOOL pagingEnabled;
@property (nonatomic, assign, getter = isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign, getter = isWrapEnabled) BOOL wrapEnabled;
@property (nonatomic, assign) BOOL delaysContentTouches;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) float decelerationRate;
@property (nonatomic, assign) CGFloat autoscroll;
@property (nonatomic, readonly, getter = isDragging) BOOL dragging;
@property (nonatomic, readonly, getter = isDecelerating) BOOL decelerating;
@property (nonatomic, readonly, getter = isScrolling) BOOL scrolling;
@property (nonatomic, assign) BOOL defersItemViewLoading;
@property (nonatomic, assign, getter = isVertical) BOOL vertical;

- (void)reloadData;
- (void)reloadItemAtIndex:(NSInteger)index;
- (void)scrollByOffset:(CGFloat)offset duration:(NSTimeInterval)duration;
- (void)scrollToOffset:(CGFloat)offset duration:(NSTimeInterval)duration;
- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;
- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration;
- (void)scrollToPage:(NSInteger)page duration:(NSTimeInterval)duration;
- (UIView *)itemViewAtIndex:(NSInteger)index;
- (NSInteger)indexOfItemView:(UIView *)view;
- (NSInteger)indexOfItemViewOrSubview:(UIView *)view;

@end


@protocol CTSwipeViewDataSource <NSObject>

- (NSInteger)numberOfItemsInSwipeView:(CTSwipeView *)swipeView;
- (UIView *)swipeView:(CTSwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view;

@end


@protocol CTSwipeViewDelegate <NSObject>
@optional

- (CGSize)swipeViewItemSize:(CTSwipeView *)swipeView;
- (void)swipeViewDidScroll:(CTSwipeView *)swipeView;
- (void)swipeViewCurrentItemIndexDidChange:(CTSwipeView *)swipeView;
- (void)swipeViewWillBeginDragging:(CTSwipeView *)swipeView;
- (void)swipeViewDidEndDragging:(CTSwipeView *)swipeView willDecelerate:(BOOL)decelerate;
- (void)swipeViewWillBeginDecelerating:(CTSwipeView *)swipeView;
- (void)swipeViewDidEndDecelerating:(CTSwipeView *)swipeView;
- (void)swipeViewDidEndScrollingAnimation:(CTSwipeView *)swipeView;
- (BOOL)swipeView:(CTSwipeView *)swipeView shouldSelectItemAtIndex:(NSInteger)index;
- (void)swipeView:(CTSwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index;

@end


#pragma GCC diagnostic pop

