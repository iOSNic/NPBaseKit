//
//  UIScrollView+NPLoadMore.m
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import "UIScrollView+NPLoadMore.h"
#import "UIScrollView+NPPullToRefresh.h"
#import "NPCommonDefines.h"
#import "NPUtil.h"
#import <objc/runtime.h>

static CGFloat const NPLoadMoreViewHeight = 44.f;
static CGFloat const NPLoadMoreViewTitleFontSize = 12.f;
static CGFloat const NPLoadMoreViewTitleToActivityIndicatorHorizontalSpacing = 5.f;
static CGFloat const NPLoadMoreViewActivityIndicatorViewWidth = 20.f;
static CGFloat const NPLoadMoreViewActivityIndicatorViewHeight = 20.f;

static NSString * const NPLoadMoreViewDefaultLoadingMoreTip = @"正在加载...";
static NSString * const NPLoadMoreViewDefaultNoMoreTip = @"没有更多内容";

@interface NPLoadMoreView : UIView<NPLoadMoreViewProtocol>

@property (nonatomic, readonly) NPLoadMoreViewState state;

@property (nonatomic, copy) NSString *loadingMoreTip;
@property (nonatomic, copy) NSString *noMoreTip;

@end

@implementation NPLoadMoreView {
    UILabel *_titleLabel;
    UIActivityIndicatorView *_activityIndicatorView;
    NPLoadMoreViewState _state;
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
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:NPLoadMoreViewTitleFontSize];
        [self addSubview:_titleLabel];
        
        [self setState:NPLoadMoreViewStateInitial];
    }
    
    return self;
}

#pragma mark - NPLoadMoreViewProtocol
+ (CGFloat)height {
    return NPLoadMoreViewHeight;
}

- (NPLoadMoreViewState)state {
    return _state;
}

- (void)setState:(NPLoadMoreViewState)state {
    _state = state;
    
    [self updateUI];
}

- (void)setLoadingMoreTip:(NSString *)loadingMoreTip {
    _loadingMoreTip = loadingMoreTip;
    
    [self updateUI];
}

- (void)setNoMoreTip:(NSString *)noMoreTip {
    _noMoreTip = noMoreTip;
    
    [self updateUI];
}

- (void)updateUI {
    switch (self.state) {
        case NPLoadMoreViewStateInitial:
            {
                [_activityIndicatorView stopAnimating];
                _activityIndicatorView.frame = CGRectZero;
                _titleLabel.text = nil;
                _titleLabel.frame = self.bounds;
            }
            break;
        case NPLoadMoreViewStateLoadingMore:
            {
                _activityIndicatorView.frame = CGRectMake(0, 0, NPLoadMoreViewActivityIndicatorViewWidth, NPLoadMoreViewActivityIndicatorViewHeight);
                [_activityIndicatorView startAnimating];
                _titleLabel.text = CHECK_VALID_STRING(self.loadingMoreTip)?self.loadingMoreTip:NPLoadMoreViewDefaultLoadingMoreTip;
                [_titleLabel sizeToFit];
                _activityIndicatorView.frame = CGRectMake((CGRectGetWidth(self.bounds) - NPLoadMoreViewActivityIndicatorViewWidth - CGRectGetWidth(_titleLabel.frame) - NPLoadMoreViewTitleToActivityIndicatorHorizontalSpacing)/2.0, (CGRectGetHeight(self.bounds) - NPLoadMoreViewActivityIndicatorViewHeight)/2.0, NPLoadMoreViewActivityIndicatorViewWidth, NPLoadMoreViewActivityIndicatorViewHeight);
                _titleLabel.frame = CGRectMake(CGRectGetMaxX(_activityIndicatorView.frame) + NPLoadMoreViewTitleToActivityIndicatorHorizontalSpacing, 0, CGRectGetWidth(_titleLabel.frame), CGRectGetHeight(self.bounds));
            }
            break;
        case NPLoadMoreViewStateNoMore:
            {
                [_activityIndicatorView stopAnimating];
                _activityIndicatorView.frame = CGRectZero;
                _titleLabel.text = CHECK_VALID_STRING(self.noMoreTip)?self.noMoreTip:NPLoadMoreViewDefaultNoMoreTip;
                _titleLabel.frame = self.bounds;
            }
            break;
    }
}

@end

@implementation NPLoadMoreObserver

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (self.delegate && [self.delegate respondsToSelector:@selector(npLoadMore_observeValueForKeyPath:ofObject:change:context:)]) {
        [self.delegate npLoadMore_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@implementation UIScrollView (NPLoadMore)

+ (void)load {
    swizzleMethod([self class], @selector(setContentSize:), @selector(np_setContentSize:));
    swizzleMethod([self class], @selector(setContentOffset:), @selector(npLoadMore_setContentOffset:));
    swizzleMethod([self class], @selector(refreshDidEnd), @selector(np_refreshDidEnd));
    swizzleMethod([self class], NSSelectorFromString(@"dealloc"), @selector(np_dealloc));
}

- (void)np_dealloc {
    [self np_dealloc];

    objc_setAssociatedObject(self, @selector(loadMoreViewClass), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(initialLoadMoreContentInset), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreDelegate), nil, OBJC_ASSOCIATION_ASSIGN);
    
    @try {
        [self.panGestureRecognizer removeObserver:self.loadMoreObserver forKeyPath:@"state"];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }
}


- (void)np_setContentSize:(CGSize)contentSize {
    [self np_setContentSize:contentSize];
    
    if (!self.loadMoreEnabled) return;
    
    self.loadMoreView.frame = CGRectMake(0, self.contentSize.height, CGRectGetWidth(self.bounds), [self heightOfLoadMoreView]);
}

- (void)npLoadMore_setContentOffset:(CGPoint)contentOffset {
    [self npLoadMore_setContentOffset:contentOffset];
    
    if (!self.loadMoreEnabled) return;
    if (self.contentInsetUpdated) return;
    if ([self isLoading] || self.loadMoreView.state == NPLoadMoreViewStateNoMore) return;
    if (self.contentSize.height - contentOffset.y - CGRectGetHeight(self.bounds) <= 0) {
        [self setContentInsetUpdated:YES];
        [self setInitialLoadMoreContentInset:self.contentInset];
        
        self.contentInset = UIEdgeInsetsMake(self.contentInset.top, self.contentInset.left, self.contentInset.bottom + [self heightOfLoadMoreView], self.contentInset.right);
        
        self.loadMoreView.state = NPLoadMoreViewStateLoadingMore;
        
        if (self.loadMoreDelegate && [self.loadMoreDelegate respondsToSelector:@selector(loadMoreWillBegin:)]) {
            [self.loadMoreDelegate loadMoreWillBegin:self];
        }
    }
}

- (void)np_refreshDidEnd {
    [self np_refreshDidEnd];
    
    [self loadMoreDidEnd];
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)heightOfLoadMoreView {
    if ([self.loadMoreViewClass respondsToSelector:@selector(height)]) {
        return [self.loadMoreViewClass height];
    }
    
    return 0.f;
}

- (Class)loadMoreViewClass {
    Class loadMoreViewClass = objc_getAssociatedObject(self, @selector(loadMoreViewClass))?:[NPLoadMoreView class];
    return loadMoreViewClass;
}

- (UIView <NPLoadMoreViewProtocol> *)loadMoreView {
    UIView <NPLoadMoreViewProtocol> *loadMoreView = objc_getAssociatedObject(self, @selector(loadMoreView));
    if (!loadMoreView) {
        loadMoreView = [[self.loadMoreViewClass alloc] init];
        loadMoreView.backgroundColor = [UIColor clearColor];
        objc_setAssociatedObject(self, @selector(loadMoreView), loadMoreView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return  loadMoreView;
}

- (NPLoadMoreObserver *)loadMoreObserver {
    NPLoadMoreObserver *loadMoreObserver = objc_getAssociatedObject(self, @selector(loadMoreObserver));
    if (!loadMoreObserver) {
        loadMoreObserver = [[NPLoadMoreObserver alloc] init];
        loadMoreObserver.delegate = self;
        objc_setAssociatedObject(self, @selector(loadMoreObserver), loadMoreObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return loadMoreObserver;
}

- (BOOL)contentInsetUpdated {
    return [objc_getAssociatedObject(self, @selector(contentInsetUpdated)) boolValue];
}

- (void)setContentInsetUpdated:(BOOL)contentInsetUpdated {
    objc_setAssociatedObject(self, @selector(contentInsetUpdated), [NSNumber numberWithBool:contentInsetUpdated], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)initialLoadMoreContentInset {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets = [objc_getAssociatedObject(self, @selector(initialLoadMoreContentInset)) UIEdgeInsetsValue];
    
    return insets;
}

- (void)setInitialLoadMoreContentInset:(UIEdgeInsets)initialLoadMoreContentInset {
    objc_setAssociatedObject(self, @selector(initialLoadMoreContentInset), [NSValue valueWithUIEdgeInsets:initialLoadMoreContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)loadMoreEnabled {
    return [objc_getAssociatedObject(self, @selector(loadMoreEnabled)) boolValue];
}

- (void)setLoadMoreEnabled:(BOOL)enabled {
    [self setLoadMoreEnabled:enabled loadMoreViewClass:nil];
}

- (void)setLoadMoreEnabled:(BOOL)enabled loadMoreViewClass:(Class<NPLoadMoreViewProtocol>)viewClass {
    objc_setAssociatedObject(self, @selector(loadMoreViewClass), viewClass && [viewClass.class isSubclassOfClass:[UIView class]] && [viewClass.class conformsToProtocol:@protocol(NPLoadMoreViewProtocol)]?viewClass:[NPLoadMoreView class], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (enabled) {
        if (self.loadMoreView.superview) return;
        self.loadMoreView.frame = CGRectMake(0, self.contentSize.height, CGRectGetWidth(self.bounds), [self heightOfLoadMoreView]);
        [self addSubview:self.loadMoreView];
        [self bringSubviewToFront:self.loadMoreView];
        
        [self.panGestureRecognizer addObserver:self.loadMoreObserver forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    else {
        if (!self.loadMoreView || !self.loadMoreView.superview) return;
        [self.loadMoreView removeFromSuperview];
        objc_setAssociatedObject(self, @selector(loadMoreView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        @try {
            [self.panGestureRecognizer removeObserver:self.loadMoreObserver forKeyPath:@"state"];
        } @catch (NSException *exception) {
            NSLog(@"exception:%@",exception);
        }
    }
}

- (void)npLoadMore_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (!self.loadMoreEnabled) return;
    if (![keyPath isEqualToString:@"state"]) return;
    if ([self isLoading] || self.loadMoreView.state == NPLoadMoreViewStateNoMore) return;
    UIGestureRecognizerState state = [change[NSKeyValueChangeNewKey] integerValue];
    switch (state) {
        case UIGestureRecognizerStateBegan:
            [self setInitialLoadMoreContentInset:self.contentInset];
            break;
        default:
            break;
    }
}

- (BOOL)isLoading {
    return self.pullToRefreshView.state == NPPullToRefreshViewStateRefreshing  || self.loadMoreView.state == NPLoadMoreViewStateLoadingMore;
}

- (id<NSPLoadMoreDelegate>)loadMoreDelegate {
    return objc_getAssociatedObject(self, @selector(loadMoreDelegate));
}

- (void)setLoadMoreDelegate:(id<NSPLoadMoreDelegate>)delegate {
    objc_setAssociatedObject(self, @selector(loadMoreDelegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (void)setLoadingMoreTip:(NSString *)tip {
    if ([self.loadMoreView respondsToSelector:@selector(setLoadingMoreTip:)]) {
        [self.loadMoreView setLoadingMoreTip:tip];
    }
}

- (void)setNoMoreTip:(NSString *)tip {
    if ([self.loadMoreView respondsToSelector:@selector(setNoMoreTip:)]) {
        [self.loadMoreView setNoMoreTip:tip];
    }
}

- (void)loadMoreDidEnd {
    [self setContentInsetUpdated:NO];
    [self.loadMoreView setState:NPLoadMoreViewStateInitial];
    self.contentInset = self.initialLoadMoreContentInset;
}

- (void)loadMoreDidEndWithNoMoreContent {
    [self.loadMoreView setState:NPLoadMoreViewStateNoMore];
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
