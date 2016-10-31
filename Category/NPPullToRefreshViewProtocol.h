//
//  NPPullToRefreshViewProtocol.h
//  NPKit
//
//  Created by Nic on 16/10/26.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NPPullToRefreshViewState) {
    NPPullToRefreshViewStateNormal,
    NPPullToRefreshViewStateReleaseToRefresh,
    NPPullToRefreshViewStateRefreshing,
    NPPullToRefreshViewStateFinished = NPPullToRefreshViewStateNormal
};

@protocol NPPullToRefreshViewProtocol <NSObject>

@required
+ (CGFloat)height;
- (NPPullToRefreshViewState)state;
- (void)setState:(NPPullToRefreshViewState)state;

@optional
- (void)setPullToRefreshTip:(NSString *)tip;
- (void)setReleaseToRefreshTip:(NSString *)tip;
- (void)setRefreshingTip:(NSString *)tip;

@end
