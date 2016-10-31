//
//  UIScrollView+NPPullToRefresh.h
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPPullToRefreshViewProtocol.h"

@protocol NSPullToRefreshDelegate <UIScrollViewDelegate>

- (void)pullToRefreshWillBegin:(UIScrollView *)scrollView;

@end

@interface UIScrollView (NPPullToRefresh)

- (void)setPullToRefreshDelegate:(id<NSPullToRefreshDelegate>)delegate;

- (void)setPullToRefreshEnabled:(BOOL)enabled;
- (void)setPullToRefreshEnabled:(BOOL)enabled pullToRefreshViewClass:(Class <NPPullToRefreshViewProtocol> )viewClass;

- (void)setPullToRefreshTip:(NSString *)tip;
- (void)setReleaseToRefreshTip:(NSString *)tip;
- (void)setRefreshingTip:(NSString *)tip;

- (void)scrollViewDidEndRefresh;

@end
