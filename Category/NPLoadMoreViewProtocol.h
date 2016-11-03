//
//  NPLoadMoreViewProtocol.h
//  NPBaseKitDemo
//
//  Created by Nic on 16/10/31.
//  Copyright © 2016年 Nic. All rights reserved.
//

typedef NS_ENUM(NSInteger, NPLoadMoreViewState) {
    NPLoadMoreViewStateLoadingMore,
    NPLoadMoreViewStateNoMore
};

@protocol NPLoadMoreViewProtocol <NSObject>

@required
+ (CGFloat)height;
- (NPLoadMoreViewState)state;
- (void)setState:(NPLoadMoreViewState)state;

@optional
- (void)setLoadingMoreTip:(NSString *)tip;
- (void)setNoMoreTip:(NSString *)tip;

@end
