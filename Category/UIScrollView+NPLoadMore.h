//
//  UIScrollView+NPLoadMore.h
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPLoadMoreViewProtocol.h"

@protocol NSLoadMoreDelegate <UIScrollViewDelegate>

- (void)loadMoreWillBegin:(UIScrollView *)scrollView;

@end

@interface UIScrollView (NPLoadMore)

- (void)setLoadMoreEnabled:(BOOL)enabled;
- (void)setLoadMoreEnabled:(BOOL)enabled loadMoreViewClass:(Class <NPLoadMoreViewProtocol> )viewClass;

- (void)setLoadMoreDelegate:(id<NSLoadMoreDelegate>)delegate;
- (void)scrollViewDidEndLoadMore; // You should call this method after loading more did end.

- (void)setLoadingMoreTip:(NSString *)tip;
- (void)setNoMoreTip:(NSString *)tip;

@end
