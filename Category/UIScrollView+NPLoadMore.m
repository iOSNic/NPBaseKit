//
//  UIScrollView+NPLoadMore.m
//  NPKit
//
//  Created by Nic on 16/10/2.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import "UIScrollView+NPLoadMore.h"
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
        
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:NPLoadMoreViewTitleFontSize];
        [self addSubview:_titleLabel];
        
        [self setState:NPLoadMoreViewStateLoadingMore];
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

@implementation UIScrollView (NPLoadMore)

+ (void)load {
    swizzleMethod([self class], @selector(setContentSize:), @selector(np_setContentSize:));
    swizzleMethod([self class], @selector(setContentOffset:), @selector(npLoadMore_setContentOffset:));
    swizzleMethod([self class], NSSelectorFromString(@"dealloc"), @selector(np_dealloc));
}

- (void)np_dealloc {
    [self np_dealloc];

    objc_setAssociatedObject(self, @selector(loadMoreViewClass), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(initialContentInset), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(loadMoreDelegate), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (self.contentSize.height - contentOffset.y - CGRectGetHeight(self.bounds) <= 0) {
        [self setContentInsetUpdated:YES];
        [self setInitialContentInset:self.contentInset];
        
        self.contentInset = UIEdgeInsetsMake(self.contentInset.top, self.contentInset.left, self.contentInset.bottom + [self heightOfLoadMoreView], self.contentInset.right);
        
        self.loadMoreView.state = NPLoadMoreViewStateLoadingMore;
        
        if (self.loadMoreDelegate && [self.loadMoreDelegate respondsToSelector:@selector(loadMoreWillBegin:)]) {
            [self.loadMoreDelegate loadMoreWillBegin:self];
        }
    }
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

- (BOOL)contentInsetUpdated {
    return [objc_getAssociatedObject(self, @selector(contentInsetUpdated)) boolValue];
}

- (void)setContentInsetUpdated:(BOOL)contentInsetUpdated {
    objc_setAssociatedObject(self, @selector(contentInsetUpdated), [NSNumber numberWithBool:contentInsetUpdated], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)initialContentInset {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets = [objc_getAssociatedObject(self, @selector(initialContentInset)) UIEdgeInsetsValue];
    
    return insets;
}

- (void)setInitialContentInset:(UIEdgeInsets)initialContentInset {
    objc_setAssociatedObject(self, @selector(initialContentInset), [NSValue valueWithUIEdgeInsets:initialContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)loadMoreEnabled {
    return [objc_getAssociatedObject(self, @selector(loadMoreEnabled)) boolValue];
}

- (void)setLoadMoreEnabled:(BOOL)enabled {
    [self setLoadMoreEnabled:enabled loadMoreViewClass:nil];
}

- (void)setLoadMoreEnabled:(BOOL)enabled loadMoreViewClass:(Class<NPLoadMoreViewProtocol>)viewClass {
    objc_setAssociatedObject(self, @selector(loadMoreViewClass), viewClass && [viewClass.class isSubclassOfClass:[UIView class]] && [viewClass.class conformsToProtocol:@protocol(NPLoadMoreViewProtocol)]?viewClass:[NPLoadMoreView class], OBJC_ASSOCIATION_ASSIGN);
    
    objc_setAssociatedObject(self, @selector(loadMoreEnabled), [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_ASSIGN);
    
    if (enabled) {
        if (self.loadMoreView.superview) return;
        self.loadMoreView.frame = CGRectMake(0, self.contentSize.height, CGRectGetWidth(self.bounds), [self heightOfLoadMoreView]);
        [self addSubview:self.loadMoreView];
    }
    else {
        if (!self.loadMoreView || !self.loadMoreView.superview) return;
        [self.loadMoreView removeFromSuperview];
        objc_setAssociatedObject(self, @selector(loadMoreView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (id<NSLoadMoreDelegate>)loadMoreDelegate {
    return objc_getAssociatedObject(self, @selector(loadMoreDelegate));
}

- (void)setLoadMoreDelegate:(id<NSLoadMoreDelegate>)delegate {
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

- (void)scrollViewDidEndLoadMore {
    [self setContentInsetUpdated:NO];
    self.contentInset = self.initialContentInset;
}

@end
