//
//  SupplyListViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/3/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "SupplyListViewController.h"
#import "UINavigationController+Title.h"
#import "SupplyListService.h"
#import "Tools.h"
#import <MBProgressHUD.h>
#import "SupplyListTableViewCell.h"
#import "SupplyListModel.h"
#import <MJRefresh.h>
#import "SupplyInfoViewController.h"
#import "UITableView+NoDataPrompt.h"
#import <Masonry.h>
#import "LMDropMenu.h"
#import "CreateSupplyService.h"
#import "MySupplyListViewController.h"

@interface SupplyListViewController ()<UITableViewDelegate, UITableViewDataSource, SupplyListServiceDelegate, LMDropDownMenuDataSource,LMDropDownMenuDelegate, CreateSupplyServiceDelegate> {
    
    NSMutableArray *_data1;
    NSMutableArray *_data2;
    NSMutableArray *_data3;
    
    NSUInteger _currentIndex;
    NSInteger _currentData1Index;
    NSInteger _currentData2Index;
    NSInteger _currentData3Index;
    
    LMDropMenu *_filterView;
}

@property (nonatomic, strong) UITableView *tableView;

// 装运里的订单
@property (nonatomic, strong) NSMutableArray *supplys;

@property (nonatomic, strong) SupplyListService *service;

// 加载第几页
@property (assign, nonatomic) NSUInteger page;

// 请求车辆类型、尺寸
@property (strong, nonatomic) CreateSupplyService *service_createSuppsy;

//
@property (strong, nonatomic) AppDelegate *app;

// 车辆类型、尺寸
@property (strong, nonatomic) GetItemListModel *itemListM;

// 下拉开始
//@property (strong, nonatomic)

@property (strong, nonatomic) NSArray *TmsOrgList;

// 请求是否成功
@property (assign, nonatomic) BOOL successOfGetTmsOrgList;

// 请求是否成功
@property (assign, nonatomic) BOOL successOfGetItemList;

@property (strong, nonatomic) NSMutableDictionary *MultiArrListTemp;

@property (strong, nonatomic) NSMutableDictionary *MultiArrList;

@end

@implementation SupplyListViewController

#define kTitle @"货源"
#define kCellName @"SupplyListTableViewCell"
#define kSUPPLY_STATE @"OPEN"
#define kPageCount 20
#define kCellHeight 166

#pragma mark - 生命周期
- (instancetype)init {
    if(self = [super init]) {
        
        self.tabBarItem.title = kTitle;
        _service = [[SupplyListService alloc] init];
        _service.delegate = self;
        self.tabBarItem.image = [UIImage imageNamed:@"ic_supply"];
        _service_createSuppsy = [[CreateSupplyService alloc] init];
        _service_createSuppsy.delegate = self;
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
//        _TmsOrgList = @[kAllTmsOrgList];
        _itemListM = [[GetItemListModel alloc] init];
//        _itemListM.supplyType = @[kAllSupplyType];
//        _itemListM.vehicleSize = @[kAllVehicleSize];
//        _itemListM.vehicleType = @[kAllVehicleType];
        
        _successOfGetTmsOrgList = NO;
        _successOfGetItemList = NO;
    }
    return self;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addNotification];
    
    [self.view addSubview:self.tableView];
    
    _data1 = [@[@""] mutableCopy];
    _data2 = [@[@""] mutableCopy];
    _data3 = [@[@""] mutableCopy];
    
    [self initDownMenuData];
    
    LMDropMenu *menu = [[LMDropMenu alloc] initWithOrigin:CGPointMake(0, 0) andHeight:kLMMenuHeight_Supply];
    menu.indicatorColor = [UIColor colorWithRed:175.0f/255.0f green:175.0f/255.0f blue:175.0f/255.0f alpha:1.0];
    menu.separatorColor = [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0];
    menu.textColor = [UIColor colorWithRed:83.f/255.0f green:83.f/255.0f blue:83.f/255.0f alpha:1.0f];
    menu.dataSource = self;
    menu.delegate = self;
    
    [self.view addSubview:menu];
    
    [_tableView.mj_header beginRefreshing];

    _successOfGetTmsOrgList = NO;
    _successOfGetItemList = NO;
    [_service_createSuppsy GetTmsOrgList:_app.user.iDX];
    [_service_createSuppsy GetItemLis:_app.user.iDX];
    
    NSLog(@"");
}


- (void)dealloc {
    
    [self removeNotification];
}


#pragma mark - 功能函数

- (void)registCell {
    
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
}


- (NSMutableArray *)getChosenTmsOrgList {
    
    NSMutableArray *ChosenTmsOrgList = [[NSMutableArray alloc] init];
    NSMutableArray *array = _MultiArrList[@(0)];
    for (int i = 0; i < array.count; i++) {
        
        DataItemModel *m = array[i];
        if(m.selected == YES) {
            
            [ChosenTmsOrgList addObject:m];
        }
    }
    return ChosenTmsOrgList;
}


- (NSMutableArray *)getChosenVehicleSize {
    
    NSMutableArray *ChosenVehicleSizeList = [[NSMutableArray alloc] init];
    NSMutableArray *array = _MultiArrList[@(1)];
    for (int i = 0; i < array.count; i++) {
        
        DataItemModel *m = array[i];
        if(m.selected == YES) {
            
            [ChosenVehicleSizeList addObject:m];
        }
    }
    return ChosenVehicleSizeList;
}


- (NSMutableArray *)getChosenVehicleType {
    
    NSMutableArray *ChosenVehicleTypeList = [[NSMutableArray alloc] init];
    NSMutableArray *array = _MultiArrList[@(2)];
    for (int i = 0; i < array.count; i++) {
        
        DataItemModel *m = array[i];
        if(m.selected == YES) {
            
            [ChosenVehicleTypeList addObject:m];
        }
    }
    return ChosenVehicleTypeList;
}


- (void)requestNetworkData {
    
    NSString *ORG_IDX = @"LM";
    NSMutableArray *array1 = [self getChosenTmsOrgList];
    if(array1.count > 0) {
        
        for (int i = 0; i < array1.count; i++) {
            
            DataItemModel *m = array1[i];
            NSString *title = m.title;
            if([m.title isEqualToString:kPersonalSupply]) {
                
                title = @"null";
            } else if([m.title isEqualToString:kOtherORG]) {
                
                title = @"dislike";
            }
            
            if(i == 0) {
                
                ORG_IDX = title;
            } else {
                
                ORG_IDX = [NSString stringWithFormat:@"%@,%@", ORG_IDX, title];
            }
        }
    }
    
    NSString *vehicleSize = @"LM";
    NSMutableArray *array2 = [self getChosenVehicleSize];
    if(array2.count > 0) {
        
        for (int i = 0; i < array2.count; i++) {
            
            DataItemModel *m = array2[i];
            if(i == 0) {
                
                vehicleSize = m.title;
            } else {
                
                vehicleSize = [NSString stringWithFormat:@"%@,%@", vehicleSize, m.title];
            }
        }
    }
    
    NSString *vehicleType = @"LM";
    NSMutableArray *array3 = [self getChosenVehicleType];
    if(array3.count > 0) {
        
        for (int i = 0; i < array3.count; i++) {
            
            DataItemModel *m = array3[i];
            if(i == 0) {
                
                vehicleType = m.title;
            } else {
                
                vehicleType = [NSString stringWithFormat:@"%@,%@", vehicleType, m.title];
            }
        } 
    }
    
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
    
    [_service GetSupplyList:result andSTART_DATE:@"2014-03-01 17:58:37" andEND_DATE:nowTime andSUPPLY_STATE:kSUPPLY_STATE andPAGE:_page andPAGE_COUNT:kPageCount andUSER_IDX:@"" andSUPPLY_WOKERFLOW:@"新建" andDRIVER_IDX:@""];
}


- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNetworkData) name:kSupplyListVC_refreshNetworkData_Notification object:nil];
}


- (void)removeNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSupplyListVC_refreshNetworkData_Notification object:nil];
}


- (void)initDownMenuData {
    
    _MultiArrListTemp = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *array1 = [[NSMutableArray alloc] init];
    for (int i = 0; i < _data1.count; i++) {
        
        DataItemModel *m = [[DataItemModel alloc] init];
        m.title = _data1[i];
        m.selected = YES;
        
        [array1 addObject:m];
    }
    
    NSMutableArray *array2 = [[NSMutableArray alloc] init];
    for (int i = 0; i < _data2.count; i++) {
        
        DataItemModel *m = [[DataItemModel alloc] init];
        m.title = _data2[i];
        m.selected = YES;
        
        [array2 addObject:m];
    }
    
    NSMutableArray *array3 = [[NSMutableArray alloc] init];
    for (int i = 0; i < _data3.count; i++) {
        
        DataItemModel *m = [[DataItemModel alloc] init];
        m.title = _data3[i];
        m.selected = YES;
        
        [array3 addObject:m];
    }
    
    _MultiArrList = [@{@(0) : [array1 copy], @(1) : [array2 copy], @(2) : [array3 copy]} mutableCopy];
    
    for (int i = 0; i < _MultiArrList.count; i++) {
        
        NSMutableArray *arrayTemp = [[NSMutableArray alloc] init];
        NSMutableArray *array = _MultiArrList[@(i)];
        for (int i = 0; i < array.count; i++) {
            
            DataItemModel *m = array[i];
            [arrayTemp addObject:[m copy]];
        }
        
        [_MultiArrListTemp addEntriesFromDictionary:@{@(i) : arrayTemp}];
    }
}


#pragma mark - 控件GET方法

- (UITableView *)tableView {
    
    if(!_tableView) {
        
        _tableView = [[UITableView alloc] init];
        
        _tableView.separatorStyle = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        [_tableView setFrame:CGRectMake(0, kLMMenuHeight_Supply, ScreenWidth, ScreenHeight - 49 - 64 - kLMMenuHeight_Supply)];
        
        [self registCell];
        
        /// 下拉刷新
        MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataDown)];
        header.lastUpdatedTimeLabel.hidden = YES;
        _tableView.mj_header = header;
        
        // 上拉分页加载
        _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataUp)];
        _tableView.mj_footer.hidden = YES;
        
        // filterView 赋给tableHeaderView
        _tableView.tableHeaderView = _filterView;
    }
    
    return _tableView;
}


- (void)loadMoreDataUp {
    
    if([Tools isConnectionAvailable]) {
        
        _page ++;
        [self requestNetworkData];
    } else {
        [Tools showAlert:self.view andTitle:@"网络连接不可用"];
    }
}


- (void)loadMoreDataDown {
    
    if([Tools isConnectionAvailable]) {
        
        _page = 1;
        [self requestNetworkData];
    } else {
        
        [Tools showAlert:self.view andTitle:@"网络连接不可用"];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"我的货源" style:UIBarButtonItemStyleDone target:self action:@selector(mySupplyList)];
    
    self.tabBarController.navigationItem.rightBarButtonItem = rightItem;
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.navigationController titleText:kTitle andColor:CMWhiteColor];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - 事件

- (void)mySupplyList {
    
    MySupplyListViewController *vc = [[MySupplyListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
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
    cell.SUPPLY_STATE_Image_nil = YES;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SupplyListModel *m = _supplys[indexPath.row];
    
    SupplyInfoViewController *vc = [[SupplyInfoViewController alloc] init];
    vc.showBidButtons = YES;
    vc.supplyIdx = m.iDX;
    
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - CreateSupplyServiceDelegate

- (void)successOfGetTmsOrgList:(NSArray *)TmsOrgList {
    
    _TmsOrgList = TmsOrgList;
    _successOfGetTmsOrgList = YES;
    
    _data1 = [_TmsOrgList mutableCopy];
    [_data1 removeObject:kAllTmsOrgList];
    [_data1 insertObject:kPersonalSupply atIndex:0];
    [_data1 addObject:kOtherORG];
    
    [self initDownMenuData];
}


- (void)failureOfGetTmsOrgList:(NSString *)msg {
    
    NSString *msg_LM = [NSString stringWithFormat:@"公司信息: %@", msg];
    
    // 避免MBProgressHUD 还没hidden 又被show
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [Tools showAlert:self.view andTitle:msg_LM];
        });
    });
}


- (void)successOfGetItemList:(GetItemListModel *)itemListM {
    
    _successOfGetItemList = YES;
    _itemListM = itemListM;
    
    _data2 = [_itemListM.vehicleSize mutableCopy];
    _data3 = [_itemListM.vehicleType mutableCopy];
    [_data2 removeObject:kAllVehicleSize];
    [_data3 removeObject:kAllVehicleType];
    
    [self initDownMenuData];
}


- (void)failureOfGetItemList:(NSString *)msg {
    
    NSString *msg_LM = [NSString stringWithFormat:@"车辆类型、尺寸、货源类型: %@", msg];
    [Tools showAlert:self.view andTitle:msg_LM];
}


#pragma mark - SupplyListServiceDelegate

- (void)successOfSupplyList:(NSArray *)supplys {
    
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
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
    
    [_tableView.mj_header endRefreshing];
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
    [_tableView.mj_footer endRefreshing];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
    [_supplys removeAllObjects];
    [_tableView reloadData];
    [_tableView noSupply:msg];
}


#pragma mark - LMDropDownMenuDelegate

- (NSInteger)numberOfColumnsInMenu:(LMDropMenu *)menu {
    
    return _MultiArrListTemp.count;
}

// 是否两栏TableView
-(BOOL)haveRightTableViewInColumn:(NSInteger)column{
    
    return NO;
}


// 下拉View 宽度
-(CGFloat)widthRatioOfLeftColumn:(NSInteger)column{
    
    return 1;
}

-(NSInteger)currentLeftSelectedRow:(NSInteger)column{
    
    if (column==0) {
        
        return _currentData1Index;
    }
    if (column==1) {
        
        return _currentData2Index;
    }
    if (column==2) {
        
        return _currentData3Index;
    }
    return 0;
}

- (NSUInteger)menu:(LMDropMenu *)menu numberOfRowsInColumn:(NSUInteger)column {
    
    NSArray *array = _MultiArrListTemp[@(column)];
    
    return array.count;
}

- (NSString *)menu:(LMDropMenu *)menu titleForColumn:(NSInteger)column{
    
    if(column == 0) {
        
        return @"城市筛选";
    } else if(column == 1) {
        
        return @"车尺寸筛选";
    } else if(column == 2) {
        
        return @"车类型筛选";
    } else {
        
        return @"";
    }
}

- (DataItemModel *)menu:(LMDropMenu *)menu titleForRowAtIndexPath:(LMIndexPath *)indexPath {
    
    NSArray *array = _MultiArrListTemp[@(indexPath.column)];
    
    DataItemModel *item = array[indexPath.row];
    
    return item;
}

- (void)menu:(LMDropMenu *)menu didSelectRowAtIndexPath:(LMIndexPath *)indexPath {
    
    NSLog(@"column:%ld  row:%ld", (long)indexPath.column, (long)indexPath.row);
    
    DataItemModel *item = _MultiArrListTemp[@(indexPath.column)][indexPath.row];
    
    item.selected = !item.selected;
}


- (void)filterComplete {
    
    for (int i = 0; i < _MultiArrListTemp.count; i++) {
        
        NSMutableArray *array = _MultiArrList[@(i)];
        NSMutableArray *arrayTemp = _MultiArrListTemp[@(i)];
        for (int i = 0; i < array.count; i++) {
            
            DataItemModel *m = array[i];
            DataItemModel *mTemp = arrayTemp[i];
            m.selected = mTemp.selected;
        }
    }
    
    _page = 1;
    [self requestNetworkData];
}


- (void)filterCancel {
    
    for (int i = 0; i < _MultiArrListTemp.count; i++) {
        
        NSMutableArray *array = _MultiArrList[@(i)];
        NSMutableArray *arrayTemp = _MultiArrListTemp[@(i)];
        for (int i = 0; i < array.count; i++) {
            
            DataItemModel *m = array[i];
            DataItemModel *mTemp = arrayTemp[i];
            mTemp.selected = m.selected;
        }
    }
}


- (void)menuTapped:(NSUInteger)touchIndex {
    
    _currentIndex = touchIndex;
}


- (void)antiElectionOnclick {
    
    NSMutableArray *arrayTemp = _MultiArrListTemp[@(_currentIndex)];
    for (int i = 0; i < arrayTemp.count; i++) {
        
        DataItemModel *mTemp = arrayTemp[i];
        mTemp.selected = !mTemp.selected;
    }
}

@end
