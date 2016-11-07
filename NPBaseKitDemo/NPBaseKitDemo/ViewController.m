//
//  ViewController.m
//  NPBaseKitDemo
//
//  Created by Nic on 16/10/28.
//  Copyright © 2016年 Nic. All rights reserved.
//

#import "ViewController.h"
#import "NPCommonDefines.h"
#import "UIScrollView+NPPullToRefresh.h"
#import "UIScrollView+NPLoadMore.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,NSPullToRefreshDelegate,NSPLoadMoreDelegate>{
    UITableView *_tableView;
    NSInteger _numberOfTimes;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _numberOfTimes = 1;
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [_tableView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
    [_tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [_tableView setPullToRefreshDelegate:self];
    [_tableView setPullToRefreshEnabled:YES];
    [_tableView setLoadMoreEnabled:YES];
    [_tableView setLoadMoreDelegate:self];
    [self.view addSubview:_tableView];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 64)];
    view.backgroundColor = [UIColor colorWithRed:0x1c/255.0 green:0x90/255.0 blue:0xf2/255.0 alpha:1.0];
    [self.view addSubview:view];
}

- (void)pullToRefreshWillBegin:(UIScrollView *)scrollView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_tableView refreshDidEnd];
        _numberOfTimes = 1;
        [_tableView reloadData];
    });
}

- (void)loadMoreWillBegin:(UIScrollView *)scrollView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _numberOfTimes += 1;
        [_tableView reloadData];
        [_tableView loadMoreDidEnd];
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15*_numberOfTimes;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
