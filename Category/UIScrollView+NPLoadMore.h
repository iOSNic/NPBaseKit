//
//  UIScrollView+NPLoadMore.h
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPLoadMoreViewProtocol.h"

@protocol NPLoadMoreObserverDelegate <NSObject>

- (void)npLoadMore_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;

@end

@interface NPLoadMoreObserver : NSObject

@property (nonatomic, weak) id<NPLoadMoreObserverDelegate>delegate;

@end

@protocol NSPLoadMoreDelegate <UIScrollViewDelegate>

- (void)loadMoreWillBegin:(UIScrollView *)scrollView;

@end

@interface UIScrollView (NPLoadMore)<NPLoadMoreObserverDelegate>

- (UIView <NPLoadMoreViewProtocol> *)loadMoreView;

- (void)setLoadMoreEnabled:(BOOL)enabled;
- (void)setLoadMoreEnabled:(BOOL)enabled loadMoreViewClass:(Class <NPLoadMoreViewProtocol> )viewClass;

- (void)setLoadMoreDelegate:(id<NSPLoadMoreDelegate>)delegate;
- (void)loadMoreDidEnd; // You should call this method after loading more did end.
- (void)loadMoreDidEndWithNoMoreContent; // You should call this method after loading more did end with no content.

- (void)setLoadingMoreTip:(NSString *)tip;
- (void)setNoMoreTip:(NSString *)tip;

@end
