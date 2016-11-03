//
//  UIScrollView+NPPullToRefresh.h
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPPullToRefreshViewProtocol.h"

@protocol NPPullToRefreshObserverDelegate <NSObject>

- (void)npPullToRefresh_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;

@end

@interface NPPullToRefreshObserver : NSObject

@property (nonatomic, weak) id<NPPullToRefreshObserverDelegate>delegate;

@end

@protocol NSPullToRefreshDelegate <UIScrollViewDelegate>

- (void)pullToRefreshWillBegin:(UIScrollView *)scrollView;

@end

@interface UIScrollView (NPPullToRefresh)<NPPullToRefreshObserverDelegate>

- (void)setPullToRefreshEnabled:(BOOL)enabled;
- (void)setPullToRefreshEnabled:(BOOL)enabled pullToRefreshViewClass:(Class <NPPullToRefreshViewProtocol> )viewClass;

- (void)setPullToRefreshDelegate:(id<NSPullToRefreshDelegate>)delegate;
- (void)scrollViewDidEndRefresh; // You should calll this method after refreshing did end.

- (void)setPullToRefreshTip:(NSString *)tip;
- (void)setReleaseToRefreshTip:(NSString *)tip;
- (void)setRefreshingTip:(NSString *)tip;

@end
