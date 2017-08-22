//
//  MySupplyListViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/6/21.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "MySupplyListViewController.h"
#import "SupplyListService.h"
#import <MBProgressHUD.h>
#import "AppDelegate.h"
#import <MJRefresh.h>
#import "SupplyListModel.h"
#import "Tools.h"
#import "UITableView+NoDataPrompt.h"
#import "SupplyListTableViewCell.h"
#import "SupplyInfoViewController.h"


@interface MySupplyListViewController ()<UITableViewDelegate, UITableViewDataSource, SupplyListServiceDelegate>

@property (nonatomic, strong) UITableView *tableView;

//
@property (strong, nonatomic) AppDelegate *app;

@property (nonatomic, strong) SupplyListService *service;

// 装运里的订单
@property (nonatomic, strong) NSMutableArray *supplys;

// 加载第几页
@property (assign, nonatomic) NSUInteger page;

@end

#define kCellName @"SupplyListTableViewCell"
#define kSUPPLY_STATE @"OPEN"
#define kTitle @"我的货源"
#define kPageCount 200
#define kCellHeight 166

@implementation MySupplyListViewController

- (instancetype)init {
    
    if(self = [super init]) {
        
        _service = [[SupplyListService alloc] init];
        _service.delegate = self;
        _page = 1;
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = kTitle;
    
    [self.view addSubview:self.tableView];
    
    [self requestNetworkData];
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - 控件GET方法

- (UITableView *)tableView {
    
    if(!_tableView) {
        
        _tableView = [[UITableView alloc] init];
        
        _tableView.separatorStyle = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        [_tableView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 64)];
        
        [self registCell];
        
        // 上拉分页加载
        _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataUp)];
        _tableView.mj_footer.hidden = YES;
    }
    
    return _tableView;
}


#pragma mark - 功能函数

- (void)registCell {
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
}


- (void)requestNetworkData {
    
    NSString *ORG_IDX = @"";
    
    NSString *vehicleSize = @"";
    
    NSString *vehicleType = @"";
    
    NSDictionary *dict = @{@"ORG_IDX" : ORG_IDX,
                           @"SUPPLY_VEHICLE_TYPE" : vehicleType,
                           @"SUPPLY_VEHICLE_SIZE" : vehicleSize,
                           @"ROUTES_CITY" : @""
                           };
    
    NSArray *array = @[dict];
    NSDictionary *dict1 = @{@"result" : array};
    NSString *result = [Tools JsonStringWithDictonary:dict1];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // 当前时间
    NSString *nowTime = [Tools getCurrentDate];
    
    [_service GetSupplyList:result andSTART_DATE:@"2014-03-01 17:58:37" andEND_DATE:nowTime andSUPPLY_STATE:kSUPPLY_STATE andPAGE:_page andPAGE_COUNT:kPageCount andUSER_IDX:@"" andSUPPLY_WOKERFLOW:@"" andDRIVER_IDX:_app.user.iDX];
}


- (void)loadMoreDataUp {
    
    if([Tools isConnectionAvailable]) {
        
        _page ++;
        [self requestNetworkData];
    } else {
        [Tools showAlert:self.view andTitle:@"网络连接不可用"];
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SupplyListModel *m = _supplys[indexPath.row];
    return m.cellHeight;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _supplys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellid = kCellName;
    
    SupplyListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
    
    SupplyListModel *m = _supplys[indexPath.row];
    
    cell.supplyListM = m;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SupplyListModel *m = _supplys[indexPath.row];
    
    SupplyInfoViewController *vc = [[SupplyInfoViewController alloc] init];
    vc.showBidButtons = NO;
    vc.supplyIdx = m.iDX;
    
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - SupplyListServiceDelegate

- (void)successOfSupplyList:(NSArray *)supplys {
    
    [_tableView.mj_header endRefreshing];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // 页数处理
    if(_page == 1) {
        
        _supplys = [supplys mutableCopy];
    } else {
        
        for(int i = 0; i < supplys.count; i++) {
            
            SupplyListModel *m = supplys[i];
            [_supplys addObject:m];
        }
    }
    
    // 线路城市处理换行
    for (int i = 0; i < _supplys.count; i++) {
        
        SupplyListModel *m = _supplys[i];
        
        CGFloat textHeight = [Tools getHeightOfString:[Tools routesCityConvert:m.rOUTESCITY] fontSize:14.0 andWidth:ScreenWidth - 58];
        CGFloat oneLineHeight = [Tools getHeightOfString:@"一行高度" fontSize:14.0 andWidth:ScreenWidth - 58]; // 这个55要自己手动量Cell里的距离
        if(textHeight > oneLineHeight) {
            
            m.cellHeight = kCellHeight + textHeight - oneLineHeight - 3; // 为了配合SupplyListTableViewCell里的3
        } else {
            m.cellHeight = kCellHeight;
        }
    }
    
    //是否隐藏上拉
    if(_supplys.count >= kPageCount) {
        
        _tableView.mj_footer.hidden = NO;
    }else {
        
        _tableView.mj_footer.hidden = YES;
    }
    
    [_tableView removeNoDataPrompt];
    
    [_tableView reloadData];
}


- (void)successOfSupplyListNoData {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if(_page == 1) { // 没有数据
        
        [_supplys removeAllObjects];
        _tableView.mj_footer.hidden = YES;
        [_tableView noSupply:@"暂时还没有货源，晚点再来看看"];
    } else {  // 已加载完毕
        
        [_tableView.mj_footer endRefreshingWithNoMoreData];
        [_tableView removeNoDataPrompt];
        [_tableView.mj_footer setCount_NoMoreData:_supplys.count];
    }
    
    [_tableView reloadData];
}


- (void)failureOfSupplyList:(NSString *)msg {
    
    [_tableView.mj_header endRefreshing];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
    [_supplys removeAllObjects];
    [_tableView noSupply:msg];
}

@end
