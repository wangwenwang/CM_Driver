//
//  PushNewsViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/2/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "PushNewsViewController.h"
#import "UINavigationController+Title.h"
#import "MyBMKLocationService.h"
#import "Tools.h"
#import "LM_alert.h"
#import "LocationService.h"
#import "PushNewsService.h"
#import "UITableView+NoDataPrompt.h"
#import "PersonalInfoService.h"
#import <MJRefresh.h>
#import <MBProgressHUD.h>
#import "PushNewsTableViewCell.h"
#import "PushOrderViewController.h"
#import "PushMsgViewController.h"

@interface PushNewsViewController ()<BMKLocationServiceDelegate, MyBMKLocationServiceDelegate, PushNewsServiceDelegate, PersonalInfoServiceDelegate, UITableViewDelegate, UITableViewDataSource> {
    
    /// 二次封装的定位
    MyBMKLocationService *_myLocationService;
    
    /// 记录用户最近坐标
    CLLocationCoordinate2D _location;
    
    /// 用户位置是否有更新
    BOOL _isUpdataLocation;
    
    LocationService *_locationService;
    
    AppDelegate *_app;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

/// 是否开启定位
@property (assign, nonatomic) BOOL startLocation;

/// 加载第几页
@property (assign, nonatomic) int page;

@property (strong, nonatomic) PushNewsService *service;

@property (strong, nonatomic) PushNewsListModel *pushNewsListM;

@end

@implementation PushNewsViewController

#define Ktitle @"消息"
#define kCellName @"PushNewsTableViewCell"
#define kNoDriverPrompt @"此车队还没有司机"

#pragma mark - 生命周期
- (instancetype)initWithStartLocation:(BOOL)startLocation {
    
    if(self = [super init]) {
        
        _startLocation = startLocation;
        
        self.tabBarItem.title = Ktitle;
        
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if(startLocation) {
            [self startLocationService];
            _locationService = [[LocationService alloc] init];
            [_locationService addObserver:self forKeyPath:@"updataLocationSpanTimeMin" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
        
        self.tabBarItem.image = [UIImage imageNamed:@"ic_news"];
        
        
        
        _service = [[PushNewsService alloc] init];
        _service.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(_startLocation) {
        
        [self startUpdataLocationTimer];
        
        //判断定位权限  延迟检查，因为用户首次选择需要时间
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            sleep(5);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([Tools isLocationServiceOpen]) {
                    LMLog(@"应用拥有定位权限");
                } else {
                    [Tools skipLocationSettings];
                }
            });
        });
    }
    
    //判断通知权限
    if([Tools isMessageNotificationServiceOpen]) {
        LMLog(@"应用拥有通知权限");
    } else {
        [Tools skipNotifiationSettings];
    }
    
    
    // 异步获取个人信息，在"我的"界面使用
    PersonalInfoService *s = [[PersonalInfoService alloc] init];
    s.delegate = self;
    [s GetUserInfo:_app.user.iDX];
    
    
    /// 下拉刷新
    MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataDown)];
    header.lastUpdatedTimeLabel.hidden = YES;
    _tableView.mj_header = header;
    
    /// 上拉分页加载
    _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataUp)];
    _tableView.mj_footer.hidden = YES;
    
    [self registerCell];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(500000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_tableView.mj_header beginRefreshing];
        });
    });
}

- (void)loadMoreDataDown {
    if([Tools isConnectionAvailable]) {
        
        _page = 1;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [_service getPushNews:_app.user.iDX andPageNumber:_page];
    }else {
        
        [Tools showAlert:self.view andTitle:@"网络连接不可用"];
    }
}


- (void)loadMoreDataUp {
    if([Tools isConnectionAvailable]) {
        
        _page ++;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [_service getPushNews:_app.user.iDX andPageNumber:_page];
    }else {
        [Tools showAlert:self.view andTitle:@"网络连接不可用"];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController titleText:Ktitle andColor:CMWhiteColor];
    
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 功能方法

- (void)registerCell {
    
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
}



#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 65;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _pushNewsListM.pushNewsModel.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = kCellName;
    
    PushNewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    PushNewsModel *pushNewM = _pushNewsListM.pushNewsModel[indexPath.row];
    
    cell.pushNewsM = pushNewM;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PushNewsModel *m = _pushNewsListM.pushNewsModel[indexPath.row];
    
    if([m.tYPE isEqualToString:@"0"]) {
        
        PushOrderViewController *vc = [[PushOrderViewController alloc] init];
        vc.orders = m.orderNoListModel;
        [self.navigationController pushViewController:vc animated:YES];
    } else if([m.tYPE isEqualToString:@"1"]) {
        
        PushMsgViewController *vc = [[PushMsgViewController alloc] init];
        vc.title1 = m.tITLE;
        vc.message = m.mESSAGE;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - PushNewsServiceDelegate

- (void)successOfGetPushNews:(PushNewsListModel *)pushNewsListM {
 
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
    _pushNewsListM = pushNewsListM;
    [_tableView reloadData];
    [_tableView removeNoDataPrompt];
}


- (void)successGetPushNewsNoData {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
    [_tableView noOrder:@"您还没有消息哦"];
}


- (void)failureOfGetPushNews:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [_tableView.mj_header endRefreshing];
    [_tableView.mj_footer endRefreshing];
    [_tableView noOrder:@"您还没有消息哦"];
}


#pragma mark - 上传定位功能函数
/// 上传位置信息
static int _i = 0;
- (void)updataLocation:(NSTimer *)timer {
    LMLog(@"准备上传位置点信息！%d", _i);
    _i++;
    
    if(TARGET_IPHONE_SIMULATOR) {
        
        LMLog(@"检测到模拟器，终止");
        return;
    }
    
    CLLocationCoordinate2D _lo = _location;
    if(_lo.latitude != 0 & _lo.longitude != 0)  {
        if(_isUpdataLocation) {
            
#ifdef DEBUG
            if([_app.user.uSERCODE isEqualToString:@"13726027405"] ||
               [_app.user.uSERCODE isEqualToString:@"123"] ||
               [_app.user.uSERCODE isEqualToString:@"13800138000"] ||
               [_app.user.uSERCODE isEqualToString:@"13800138001"] ||
               [_app.user.uSERCODE isEqualToString:@"13800138002"] ||
               [_app.user.uSERCODE isEqualToString:@"13800138003"]) {
                LMLog(@"是本人帐号，开启上传位置功能");
#else
#endif
                //判断连接状态
                if([Tools isConnectionAvailable]) {
                    LMLog(@"位置更改，上传");
                    [_locationService updataLocation:_lo];
                }else {
                    LMLog(@"位置更改，保存（网络不可用）");
                    [_locationService saveLocationPointInLocal:_lo];
                }
                LMLog(@"%s: %f   %f", __func__, _location.latitude, _location.longitude);
                
#ifdef DEBUG
            }else {
                LMLog(@"不是本人帐号，不开启上传位置功能");
            }
#else
#endif
            
            
            _isUpdataLocation = NO;
        } else {
            LMLog(@"检测位置未改变，不操作");
        }
    } else {
        LMLog(@"坐标为0，不操作");
    }
}


- (void)startLocationService {
    // 百度地图定位服务
    _myLocationService = [[MyBMKLocationService alloc] init];
    _myLocationService.delegate = self;
    _myLocationService.myDelegate = self;
}


/// 开启间隔时间上传位置点计时器
- (void)startUpdataLocationTimer {
    if(_localTimer != nil) {
        [_localTimer invalidate];
        LMLog(@"关闭定时上传位置点信息计时器");
    }
    
    _localTimer = [NSTimer scheduledTimerWithTimeInterval:[_locationService.updataLocationSpanTimeMin floatValue] * 60 target:self selector:@selector(updataLocation:) userInfo:nil repeats:YES];
    LMLog(@"开启定时上传位置点信息计时器");
}


#pragma mark - MyBMKLocationServiceDelegate
- (void)successUploadLocation:(BMKUserLocation *)userLocation {
    _location = userLocation.location.coordinate;
    LMLog(@"经度X:%f, 纬度Y:%f, 精度:%f", _location.longitude, _location.latitude, userLocation.location.horizontalAccuracy);
    
    _isUpdataLocation = YES;
}

/**
 *定位失败后，会调用此函数
 *@param code 错误码
 */
- (void)failureUploadLocation:(NSInteger)code {
    LMLog(@"定位失败，错误码：%ld", (long)code);
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"updataLocationSpanTimeMin"]) {
        CGFloat oldTime = [change[@"old"] floatValue];
        CGFloat newTime = [change[@"new"] floatValue];
        if(oldTime != newTime) {
#ifdef DEBUG
#else
            [self startUpdataLocationTimer];
#endif
        }
    } else {
        //        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)dealloc {
    
    [_locationService removeObserver:self forKeyPath:@"updataLocationSpanTimeMin"];
    LMLog(@"dealloc");
}

#pragma mark - PersonalInfoServiceDelegate

// 异步获取个人信息
- (void)successOfGetUserInfo:(UserModel *)userM {
    
    _app.user.aDDRESS = userM.aDDRESS;
    if(!_app.user.aDDDATE) _app.user.aDDDATE = userM.aDDDATE;
    if(!_app.user.cOMPANYNAME) _app.user.cOMPANYNAME = userM.cOMPANYNAME;
    if(!_app.user.eDITDATE) _app.user.eDITDATE = userM.eDITDATE;
    if(!_app.user.fLEETTYPE) _app.user.fLEETTYPE = userM.fLEETTYPE;
    if(!_app.user.oPERATORIDX) _app.user.oPERATORIDX = userM.oPERATORIDX;
    if(!_app.user.rECOMNAME) _app.user.rECOMNAME = userM.rECOMNAME;
    _app.user.uSERNAME = userM.uSERNAME;
    if(!_app.user.uSERTYPE) _app.user.uSERTYPE = userM.uSERTYPE;
    _app.user.uSERCODE = userM.uSERCODE;
    _app.user.avatar = userM.avatar;
    
    // 计算用户开始使用APP至今的天数并记录下来
    NSDate *ValueDate = [Tools stringConvertDate:_app.user.aDDDATE];
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:ValueDate];
    _app.user.useDays = [NSString stringWithFormat:@"%d", ((int)time) / (3600 * 24)];
}

@end
