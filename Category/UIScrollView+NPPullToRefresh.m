//
//  UIScrollView+NPPullToRefresh.m
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import "UIScrollView+NPPullToRefresh.h"
#import "NPCommonDefines.h"
#import "NPUtil.h"
#import <objc/runtime.h>

static CGFloat const NPPullToRefreshViewHeight = 44.f;
static CGFloat const NPPullToRefreshViewTitleFontSize = 12.f;
static CGFloat const NPPullToRefreshViewTitleToActivityIndicatorHorizontalSpacing = 5.f;
static CGFloat const NPPullToRefreshViewActivityIndicatorViewWidth = 20.f;
static CGFloat const NPPullToRefreshViewActivityIndicatorViewHeight = 20.f;

static NSString * const NPPullToRefreshViewDefaultPullToRefreshTip = @"下拉可以刷新";
static NSString * const NPPullToRefreshViewDefaultReleaseToRefreshTip = @"释放即可刷新";
static NSString * const NPPullToRefreshViewDefaultRefreshingTip = @"正在刷新";

@interface NPPullToRefreshView : UIView<NPPullToRefreshViewProtocol>

@property (nonatomic, readonly) NPPullToRefreshViewState state;

@property (nonatomic, copy) NSString *pullToRefreshTip;
@property (nonatomic, copy) NSString *releaseToRefreshTip;
@property (nonatomic, copy) NSString *refreshingTip;

@end

@implementation NPPullToRefreshView {
    UILabel *_titleLabel;
    UIActivityIndicatorView *_activityIndicatorView;
    NPPullToRefreshViewState _state;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:NPPullToRefreshViewTitleFontSize];
        [self addSubview:_titleLabel];
        
        [self setState:NPPullToRefreshViewStateNormal];
    }
    
    return self;
}

#pragma mark - NPPullToRefreshViewProtocol
+ (CGFloat)height {
    return NPPullToRefreshViewHeight;
}

- (NPPullToRefreshViewState)state {
    return _state;
}

- (void)setState:(NPPullToRefreshViewState)state {
    _state = state;
    
    [self updateUI];
}

- (void)setPullToRefreshTip:(NSString *)pullToRefreshTip {
    _pullToRefreshTip = pullToRefreshTip;
    
    [self updateUI];
}

- (void)setReleaseToRefreshTip:(NSString *)releaseToRefreshTip {
    _releaseToRefreshTip = releaseToRefreshTip;
    
    [self updateUI];
}

- (void)setRefreshingTip:(NSString *)refreshingTip {
    _refreshingTip = refreshingTip;
    
    [self updateUI];
}

- (void)updateUI {
    switch (self.state) {
        case NPPullToRefreshViewStateNormal:
        {
            [_activityIndicatorView stopAnimating];
            _activityIndicatorView.frame = CGRectZero;
            _titleLabel.text = CHECK_VALID_STRING(self.pullToRefreshTip)?self.pullToRefreshTip:NPPullToRefreshViewDefaultPullToRefreshTip;
            _titleLabel.frame = self.bounds;
        }
            break;
        case NPPullToRefreshViewStateReleaseToRefresh:
        {
            [_activityIndicatorView stopAnimating];
            _activityIndicatorView.frame = CGRectZero;
            _titleLabel.text = CHECK_VALID_STRING(self.releaseToRefreshTip)?self.releaseToRefreshTip:NPPullToRefreshViewDefaultReleaseToRefreshTip;
            _titleLabel.frame = self.bounds;
        }
            
            break;
        case NPPullToRefreshViewStateRefreshing:
        {
            _activityIndicatorView.frame = CGRectMake(0, 0, NPPullToRefreshViewActivityIndicatorViewWidth, NPPullToRefreshViewActivityIndicatorViewHeight);
            [_activityIndicatorView startAnimating];
            _titleLabel.text = CHECK_VALID_STRING(self.refreshingTip)?self.refreshingTip:NPPullToRefreshViewDefaultRefreshingTip;
            [_titleLabel sizeToFit];
            _activityIndicatorView.frame = CGRectMake((CGRectGetWidth(self.bounds) - NPPullToRefreshViewActivityIndicatorViewWidth - CGRectGetWidth(_titleLabel.frame) - NPPullToRefreshViewTitleToActivityIndicatorHorizontalSpacing)/2.0, (CGRectGetHeight(self.bounds) - NPPullToRefreshViewActivityIndicatorViewHeight)/2.0, NPPullToRefreshViewActivityIndicatorViewWidth, NPPullToRefreshViewActivityIndicatorViewHeight);
            _titleLabel.frame = CGRectMake(CGRectGetMaxX(_activityIndicatorView.frame) + NPPullToRefreshViewTitleToActivityIndicatorHorizontalSpacing, 0, CGRectGetWidth(_titleLabel.frame), CGRectGetHeight(self.bounds));
        }
            break;
    }
}

@end

@implementation UIScrollView (NPPullToRefresh)

+ (void)load {
    swizzleMethod([self class], @selector(setContentOffset:), @selector(np_setContentOffset:));
    swizzleMethod([self class], NSSelectorFromString(@"dealloc"), @selector(np_dealloc));
}

- (void)np_dealloc {
    [self np_dealloc];
    
    @try {
        [self.panGestureRecognizer removeObserver:self forKeyPath:@"state"];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }
}

- (void)np_setContentOffset:(CGPoint)contentOffset {
    [self np_setContentOffset:contentOffset];
    
    if (!self.pullToRefreshView || ![self.pullToRefreshView respondsToSelector:@selector(setState:)] || ![self.pullToRefreshView respondsToSelector:@selector(state)]) return;
    if (self.pullToRefreshView.state == NPPullToRefreshViewStateRefreshing) return;
    
    if (contentOffset.y > -([self heightOfPullToRefreshView] + self.contentInset.top)) {
        self.pullToRefreshView.state = NPPullToRefreshViewStateNormal;
    }
    else if (contentOffset.y < -([self heightOfPullToRefreshView] + self.contentInset.top)) {
        self.pullToRefreshView.state = NPPullToRefreshViewStateReleaseToRefresh;
    }
}

- (CGFloat)heightOfPullToRefreshView {
    if ([self.pullToRefreshViewClass respondsToSelector:@selector(height)]) {
        return [self.pullToRefreshViewClass height];
    }
    
    return 0.f;
}

- (Class)pullToRefreshViewClass {
    Class pullToRefreshViewClass = objc_getAssociatedObject(self, @selector(pullToRefreshViewClass))?:[NPPullToRefreshView class];
    return pullToRefreshViewClass;
}

- (UIView <NPPullToRefreshViewProtocol> *)pullToRefreshView {
    UIView <NPPullToRefreshViewProtocol> *pullToRefreshView = objc_getAssociatedObject(self, @selector(pullToRefreshView));
    if (!pullToRefreshView) {
        pullToRefreshView = [[self.pullToRefreshViewClass alloc] init];
        pullToRefreshView.backgroundColor = [UIColor clearColor];
        pullToRefreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        objc_setAssociatedObject(self, @selector(pullToRefreshView), pullToRefreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return  pullToRefreshView;
}

- (void)setInitialContentInset:(UIEdgeInsets)initialContentInset {
    objc_setAssociatedObject(self, @selector(initialContentInset), [NSValue valueWithUIEdgeInsets:initialContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)initialContentInset {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets = [objc_getAssociatedObject(self, @selector(initialContentInset)) UIEdgeInsetsValue];
    
    return insets;
}

- (id<NSPullToRefreshDelegate>)pullToRefreshDelegate {
    return objc_getAssociatedObject(self, @selector(pullToRefreshDelegate));
}

- (void)setPullToRefreshDelegate:(id<NSPullToRefreshDelegate>)pullToRefreshDelegate {
    objc_setAssociatedObject(self, @selector(pullToRefreshDelegate), pullToRefreshDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (void)setPullToRefreshEnabled:(BOOL)enabled {
    [self setPullToRefreshEnabled:enabled pullToRefreshViewClass:nil];
}

- (void)setPullToRefreshEnabled:(BOOL)enabled pullToRefreshViewClass:(Class <NPPullToRefreshViewProtocol> )viewClass {
    objc_setAssociatedObject(self, @selector(pullToRefreshViewClass), viewClass && [viewClass.class isSubclassOfClass:[UIView class]] && [viewClass.class conformsToProtocol:@protocol(NPPullToRefreshViewProtocol)]?viewClass:[NPPullToRefreshView class], OBJC_ASSOCIATION_ASSIGN);
    
    if (enabled) {
        if (self.pullToRefreshView.superview) return;
        self.pullToRefreshView.frame = CGRectMake(0, -[self heightOfPullToRefreshView], CGRectGetWidth(self.bounds), [self heightOfPullToRefreshView]);
        [self addSubview:self.pullToRefreshView];
        
        [self.panGestureRecognizer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    else {
        if (!self.pullToRefreshView || !self.pullToRefreshView.superview) return;
        [self.pullToRefreshView removeFromSuperview];
        objc_setAssociatedObject(self, @selector(pullToRefreshView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        @try {
            [self.panGestureRecognizer removeObserver:self forKeyPath:@"state"];
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",exception);
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![keyPath isEqualToString:@"state"]) return;
    if (self.pullToRefreshView.state == NPPullToRefreshViewStateRefreshing) return;
    UIGestureRecognizerState state = [change[NSKeyValueChangeNewKey] integerValue];
    switch (state) {
        case UIGestureRecognizerStateBegan:
            [self setInitialContentInset:self.contentInset];
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (self.pullToRefreshView.state == NPPullToRefreshViewStateReleaseToRefresh) {
                self.pullToRefreshView.state = NPPullToRefreshViewStateRefreshing;
                [UIView animateWithDuration:.2 animations:^{
                    self.contentInset = UIEdgeInsetsMake(self.contentInset.top + [self heightOfPullToRefreshView], self.contentInset.left, self.contentInset.bottom, self.contentInset.right);
                }];
                if (self.pullToRefreshDelegate && [self.pullToRefreshDelegate respondsToSelector:@selector(pullToRefreshWillBegin:)]) {
                    [self.pullToRefreshDelegate pullToRefreshWillBegin:self];
                }
            }
        }
            break;
        default:
            break;
    }
}

- (void)setPullToRefreshTip:(NSString *)tip {
    if ([self.pullToRefreshView respondsToSelector:@selector(setPullToRefreshTip:)]) {
        [self.pullToRefreshView setPullToRefreshTip:tip];
    }
}

- (void)setReleaseToRefreshTip:(NSString *)tip {
    if ([self.pullToRefreshView respondsToSelector:@selector(setPullToRefreshTip:)]) {
        [self.pullToRefreshView setReleaseToRefreshTip:tip];
    }
}

- (void)setRefreshingTip:(NSString *)tip {
    if ([self.pullToRefreshView respondsToSelector:@selector(setPullToRefreshTip:)]) {
        [self.pullToRefreshView setRefreshingTip:tip];
    }
}

- (void)scrollViewDidEndRefresh {
    self.pullToRefreshView.state = NPPullToRefreshViewStateFinished;
    
    [UIView animateWithDuration:.25 animations:^{
        self.contentInset = self.initialContentInset;
    }];
}

@end
