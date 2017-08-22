//
//  SupplyInfoViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/3/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "SupplyInfoViewController.h"
#import "SupplyInfoService.h"
#import "RoutesTableViewCell.h"
#import <MBProgressHUD.h>
#import "Tools.h"
#import "FleetListViewController.h"
#import "DriverListViewController.h"
#import "TruckListViewController.h"
#import "FleetModel.h"
#import "DriverModel.h"
#import "TruckModel.h"
#import "IB_UIButton.h"
#import "DriverDetailViewController.h"
#import "TruckDetailViewController.h"
#import "MySupplyListViewController.h"

@interface SupplyInfoViewController ()<SupplyInfoServiceDelegate>


// 竞标信息提示
@property (weak, nonatomic) IBOutlet UIView *bidInfoPromptView;

// 竞标信息
@property (weak, nonatomic) IBOutlet UIView *bidInfoView;

// 竞标信息提示高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bidInfoPromptViewHeight;

// 竞标信息高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bidInfoViewHeight;

// 货源单号
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_NO;

// 创建时间
@property (weak, nonatomic) IBOutlet UILabel *ADD_DATE;

// 到仓时间
@property (weak, nonatomic) IBOutlet UILabel *REQUEST_WAREHOUSE;

// 交付时间
@property (weak, nonatomic) IBOutlet UILabel *REQUEST_ISSUE;

// 发布公司
@property (weak, nonatomic) IBOutlet UILabel *ORG_NAME;

// 配送经验要求(司机要求)
@property (weak, nonatomic) IBOutlet UILabel *DRIVER_REQUEST;

// 司机搬运程度
@property (weak, nonatomic) IBOutlet UILabel *HANDLING_DEGREE;

// 备注（任务补充说明）
@property (weak, nonatomic) IBOutlet UILabel *TASK_DESCRIPTION;

// 线路城市
@property (weak, nonatomic) IBOutlet UILabel *ROUTES_CITY;

// 货物类型
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_TYPE;

// 是否返仓
@property (weak, nonatomic) IBOutlet UILabel *IS_RETURN_STORE;

// 是否需要回单
@property (weak, nonatomic) IBOutlet UILabel *IS_RETURN;

// 是否需要自带搬运
@property (weak, nonatomic) IBOutlet UILabel *IS_HANDLING;

// 是否有人帮忙装货
@property (weak, nonatomic) IBOutlet UILabel *HAVE_LOAD;

// 是否有人帮忙卸货
@property (weak, nonatomic) IBOutlet UILabel *HAVE_UNLOAD;

// 要求车辆尺寸
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_VEHICLE_SIZE;

// 要求车辆类型
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_VEHICLE_TYPE;

// 整车体积
@property (weak, nonatomic) IBOutlet UILabel *TOTAL_VOLUME;

// 整车重量
@property (weak, nonatomic) IBOutlet UILabel *TOTAL_WEIGHT;

// 总件数
@property (weak, nonatomic) IBOutlet UILabel *TOTAL_QTY;

// 运费金额
@property (weak, nonatomic) IBOutlet UILabel *TOTAL_AMOUNT;

// 货源状态
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_STATE;

// 货源流程
@property (weak, nonatomic) IBOutlet UILabel *SUPPLY_WOKERFLOW;

// App
@property (strong, nonatomic) AppDelegate *app;

// 货源详情服务
@property (strong, nonatomic) SupplyInfoService *service;

// 货源详情数据
@property (strong, nonatomic) SupplyInfoModel *supplyInfoM;

// 线路信息
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// SxcrollContentView 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentViewHeight;

// 货源详情提示View 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *supplyInfoPromptViewHeight;

// 货源详情View 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *supplyInfoViewHeight;

// 线路信息View 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *routesPromptViewHeight;

// 线路城市 bottom (备注 top)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ROUTES_CITY_Bottom;

// 准备接收 货源
@property (weak, nonatomic) IBOutlet UIButton *realyCommitBtn;

// 选择运输车队
@property (weak, nonatomic) IBOutlet UIButton *chooseFleetBtn;

// 选择运输司机
@property (weak, nonatomic) IBOutlet UIButton *chooseDriverBtn;

// 选择运输车辆
@property (weak, nonatomic) IBOutlet UIButton *chooseTruckBtn;

// 已选择的车队信息
@property (strong, nonatomic) FleetModel *chooseFleetM;

// 已选择的司机信息
@property (strong, nonatomic) DriverModel *chooseDriverM;

// 已选择的车辆信息
@property (strong, nonatomic) TruckModel *chooseTruckM;

// 统计换行长度
@property (weak, nonatomic) IBOutlet UILabel *ROUTES_CITY_PromptLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ROUTES_CITY_trailing;

// 竞标按钮容器
@property (weak, nonatomic) IBOutlet UIView *buttonsView;

// 竞标按钮容器高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonsViewHeight;

@end


#define kCellName @"RoutesTableViewCell"
#define kCellHeight 70


@implementation SupplyInfoViewController


#pragma mark - 生命周期

- (instancetype)init {
    if(self = [super init]) {
        
        _service = [[SupplyInfoService alloc] init];
        _service.delegate = self;
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"货源详情";
    
    [self initUI];
    
    [self requestNetworkData];
    
    [self registCell];
    
    [self addNotification];
    
    BOOL showBidInfo = NO;
    for(int i = 0; i < self.navigationController.viewControllers.count; i++) {
        
        UIViewController *vc = self.navigationController.viewControllers[i];
        if([vc isKindOfClass:[MySupplyListViewController class]]) {
         
            showBidInfo = YES;
        }
    }
    
    if(!showBidInfo) {
        
        [_bidInfoPromptView setHidden:YES];
        [_bidInfoView setHidden:YES];
        _bidInfoPromptViewHeight.constant = 0;
        _bidInfoViewHeight.constant = 0;
    }
}


- (void)updateViewConstraints {
    
    [super updateViewConstraints];
    
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
    
    [self removeNotification];
}


#pragma mark - 事件

// 司机信息
- (IBAction)driverDetailOnclick:(IB_UIButton *)sender {
    
    DriverDetailViewController *vc = [[DriverDetailViewController alloc] init];
    vc.DRIVER_TEL = _supplyInfoM.supplyModel.dRIVERTEL;
    [self.navigationController pushViewController:vc animated:YES];
}


// 车辆信息
- (IBAction)truckDetailOnclick:(IB_UIButton *)sender {
    
    TruckDetailViewController *vc = [[TruckDetailViewController alloc] init];
    vc.PLATE_NUMBER = _supplyInfoM.supplyModel.pLATENUMBER;
    vc.strFleetIdx = _supplyInfoM.supplyModel.fLEETIDX;
    [self.navigationController pushViewController:vc animated:YES];
}


// 选择运输车队
- (IBAction)chooseFleetOnclick:(UIButton *)sender {
    
    FleetListViewController *vc = [[FleetListViewController alloc] init];
    vc.title = @"选择车队";
    [self.navigationController pushViewController:vc animated:YES];
}


// 选择运输司机
- (IBAction)chooseDriverOnclick:(UIButton *)sender {
    
    if(_chooseFleetM) {
        
        DriverListViewController *vc = [[DriverListViewController alloc] init];
        
        vc.fleetIdx = _chooseFleetM.iDX;
        vc.title = @"司机";
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        
        [Tools showAlert:self.view andTitle:@"请选择车队"];
    }
}


// 选择运输车辆
- (IBAction)chooseTruckOnclick:(id)sender {
    
    if(_chooseFleetM) {
        
        TruckListViewController *vc = [[TruckListViewController alloc] init];
        vc.fleetIdx = _chooseFleetM.iDX;
        vc.title = @"选择车辆";
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        
        [Tools showAlert:self.view andTitle:@"请选择车队"];
    }
}


// 准备接收货源
- (IBAction)readyCommit:(UIButton *)sender {
    
    //    2017-03-10 15:07:45.276 CMDriver[1780:702439] <0x14f0fa360 AddTruckServer.m:(45)> 请求添加车辆参数:
    //    {
    //        "VEHICLE_MODEL" : "牵引车",
    //        "VEHICLE_COLOR" : "蓝色",
    //        "FLEET_ID" : "55",
    //        "VEHICLE_SIZE" : "15*1.8*3米",
    //        "BRAND_MODEL" : "东风",
    //        "MAX_VOLUME" : 3000,
    //        "strLicense" : "",
    //        "PLATE_NUMBER" : "12",
    //        "MAX_WEIGHT" : 57,
    //        "USER_IDX" : "4"
    //    }
    
    
    
    // 车队ID
    NSString *fleetID = _chooseFleetM.iDX;
    // 车队名字
    NSString *fleetName = _chooseFleetM.fLEETNAME;
    // 车辆ID
    NSString *vehicleID = _chooseTruckM.iDX;
    // 车牌号
    NSString *plateNumber = _chooseTruckM.pLATENUMBER;
    // 车辆类型
    NSString *vehicleType = _chooseTruckM.vEHICLEMODEL;
    // 车辆尺寸
    NSString *vehicleSize = _chooseTruckM.vEHICLESIZE;
    // 车辆品牌
    NSString *brandModel = _chooseTruckM.bRANDMODEL;
    // 装载id
    NSString *shipmentId = _supplyIdx;
    // 司机ID
    NSString *driverId = _chooseDriverM.iDX;
    // 司机名
    NSString *driverName = _chooseDriverM.dRIVERNAME;
    // 司机手机
    NSString *driverTel = _chooseDriverM.cONTACTTEL;
    // 版本号
    NSString *version = @"1.0";
    
    NSString *msg = @"";
    if(fleetID && ![fleetID isEqualToString:@""]) {
        
        if(driverId && ![driverId isEqualToString:@""]) {
            
            if(vehicleID && ![vehicleID isEqualToString:@""]) {
                
                [_service ReceivingSupply:_app.user.iDX andUSER_TEL:_app.user.uSERCODE andFLEET_IDX:fleetID andFLEET_NAME:fleetName andVEHICLE_IDX:vehicleID andPLATE_NUMBER:plateNumber andVEHICLE_TYPE:vehicleType andVEHICLE_SIZE:vehicleSize andBRAND_MODEL:brandModel andIDX:shipmentId andDRIVER_IDX:driverId andDRIVER_NAME:driverName andDRIVER_TEL:driverTel andVERSION_NUMBER:version];
            } else  {
                
                msg = @"请选择运输车辆";
            }
        } else {
            
            msg = @"请选择运输司机";
        }
    } else {
        
        msg = @"请选择车队名称";
    }
    
    [Tools showAlert:self.view andTitle:msg];
}


#pragma mark - 功能函数

- (void)initUI {
    
    _SUPPLY_NO.text = @"";
    _ADD_DATE.text = @"";
    _REQUEST_WAREHOUSE.text = @"";
    _REQUEST_ISSUE.text = @"";
    _ORG_NAME.text = @"";
    _DRIVER_REQUEST.text = @"";
    _HANDLING_DEGREE.text = @"";
    _TASK_DESCRIPTION.text = @"";
    _ROUTES_CITY.text = @"";
    _SUPPLY_TYPE.text = @"";              // 10
    _IS_RETURN_STORE.text = @"";
    _IS_RETURN.text = @"";
    _IS_HANDLING.text = @"";
    _HAVE_LOAD.text = @"";
    _HAVE_UNLOAD.text = @"";
    _SUPPLY_VEHICLE_SIZE.text = @"";
    _SUPPLY_VEHICLE_TYPE.text = @"";
    _TOTAL_VOLUME.text = @"";
    _TOTAL_WEIGHT.text = @"";
    _TOTAL_QTY.text = @"";                // 20
    _TOTAL_AMOUNT.text = @"";
    _SUPPLY_STATE.text = @"";
    _SUPPLY_WOKERFLOW.text = @"";
}

- (void)registCell {
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
}


- (void)requestNetworkData {
    
    [_service GetSupplyInfo:_supplyIdx];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}


- (void)refreshFleet:(NSNotification *)aNotify {
    
    FleetModel *fleetM = aNotify.userInfo[@"fleetM"];
    _chooseFleetM = fleetM;
    NSString *text = [NSString stringWithFormat:@"车队:%@", fleetM.fLEETNAME];
    [_chooseFleetBtn setTitle:text forState:UIControlStateNormal];
    
    // 选择车队后，清除司机与车辆
    NSString *text1 = @"请选择运输司机";
    [_chooseDriverBtn setTitle:text1 forState:UIControlStateNormal];
    _chooseDriverM = nil;
    NSString *text2 = @"请选择运输车辆";
    [_chooseTruckBtn setTitle:text2 forState:UIControlStateNormal];
    _chooseTruckM = nil;
}


- (void)refreshDriver:(NSNotification *)aNotify {
    
    DriverModel *driverM = aNotify.userInfo[@"driverM"];
    _chooseDriverM = driverM;
    NSString *text = [NSString stringWithFormat:@"司机:%@", driverM.dRIVERNAME];
    [_chooseDriverBtn setTitle:text forState:UIControlStateNormal];
}


- (void)refreshTruck:(NSNotification *)aNotify {
    
    TruckModel *truckM = aNotify.userInfo[@"truckM"];
    _chooseTruckM = truckM;
    NSString *text = [NSString stringWithFormat:@"车辆:%@", truckM.pLATENUMBER];
    [_chooseTruckBtn setTitle:text forState:UIControlStateNormal];
}


- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFleet:) name:kSupplyInfoVC_refreshFleet_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDriver:) name:kSupplyInfoVC_refreshDriver_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTruck:) name:kSupplyInfoVC_refreshTruck_Notification object:nil];
}


- (void)removeNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSupplyInfoVC_refreshFleet_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSupplyInfoVC_refreshDriver_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSupplyInfoVC_refreshTruck_Notification object:nil];
}


#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _supplyInfoM.routesModel.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RoutesModel *routeM = _supplyInfoM.routesModel[indexPath.row];
    return routeM.cellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = kCellName;
    
    RoutesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    RoutesModel *m = _supplyInfoM.routesModel[indexPath.row];
    
    if(_supplyInfoM.routesModel.count == indexPath.row + 1) {
        
        cell.lastTO = YES;
    }
    
    cell.routesM = m;
    
    return cell;
}


- (NSString *)isNeed:(NSString *)yesOrNo {
    
    if([yesOrNo isEqualToString:@"Y"]) {
        
        return @"是";
    } else if([yesOrNo isEqualToString:@"N"]) {
        
        return @"否";
    } else {
        
        return yesOrNo;
    }
}


#pragma mark - SupplyInfoServiceDelegate

- (void)successOfSupplyInfo:(SupplyInfoModel *)supplyInfoM {
    
    _supplyInfoM = supplyInfoM;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    _SUPPLY_NO.text = _supplyInfoM.supplyModel.sUPPLYNO;
    _ADD_DATE.text = _supplyInfoM.supplyModel.aDDDATE;
    _REQUEST_WAREHOUSE.text = _supplyInfoM.supplyModel.rEQUESTWAREHOUSE;
    _REQUEST_ISSUE.text = _supplyInfoM.supplyModel.rEQUESTISSUE;
    _ORG_NAME.text = [_supplyInfoM.supplyModel.oRGNAME isEqualToString:@""] ? @"个人货源" : _supplyInfoM.supplyModel.oRGNAME;
    _DRIVER_REQUEST.text = _supplyInfoM.supplyModel.dRIVERREQUEST;
    _HANDLING_DEGREE.text = _supplyInfoM.supplyModel.hANDLINGDEGREE;
    _TASK_DESCRIPTION.text = _supplyInfoM.supplyModel.tASKDESCRIPTION;
    _ROUTES_CITY.text = [Tools routesCityConvert:_supplyInfoM.supplyModel.rOUTESCITY];
    _SUPPLY_TYPE.text = _supplyInfoM.supplyModel.sUPPLYTYPE;
    // 10
    _IS_RETURN_STORE.text = [self isNeed:_supplyInfoM.supplyModel.iSRETURNSTORE];   
    _IS_RETURN.text = [self isNeed:_supplyInfoM.supplyModel.iSRETURN];
    _IS_HANDLING.text = [self isNeed:_supplyInfoM.supplyModel.iSHANDLING];
    _HAVE_LOAD.text = [self isNeed:_supplyInfoM.supplyModel.hAVELOAD];
    _HAVE_UNLOAD.text = [self isNeed:_supplyInfoM.supplyModel.hAVEUNLOAD];
    _SUPPLY_VEHICLE_SIZE.text = _supplyInfoM.supplyModel.sUPPLYVEHICLESIZE;
    _SUPPLY_VEHICLE_TYPE.text = _supplyInfoM.supplyModel.sUPPLYVEHICLETYPE;
    _TOTAL_VOLUME.text = [NSString stringWithFormat:@"%.2f方", [Tools twoDecimal:_supplyInfoM.supplyModel.tOTALVOLUME]];
    _TOTAL_WEIGHT.text = [NSString stringWithFormat:@"%.2f吨", [Tools twoDecimal:_supplyInfoM.supplyModel.tOTALWEIGHT]];
    _TOTAL_QTY.text = [NSString stringWithFormat:@"%.1f箱", [Tools twoDecimal:_supplyInfoM.supplyModel.tOTALQTY]];
    // 10
    _TOTAL_AMOUNT.text = [NSString stringWithFormat:@"￥%.1f", [Tools twoDecimal:_supplyInfoM.supplyModel.tOTALAMOUNT]];
    _SUPPLY_STATE.text = [Tools getSupplyStatus:_supplyInfoM.supplyModel.sUPPLYSTATE];
    _SUPPLY_WOKERFLOW.text = _supplyInfoM.supplyModel.sUPPLYWOKERFLOW;
    
    /*************  路线城市换行  *************/
    [_ROUTES_CITY_PromptLabel sizeToFit];
    // Label 容器宽度
    CGFloat contentWidth = ScreenWidth - CGRectGetMinX(_ROUTES_CITY_PromptLabel.frame) - CGRectGetWidth(_ROUTES_CITY_PromptLabel.frame) - _ROUTES_CITY_trailing.constant;
    // Label 单行高度
    CGFloat oneLineHeight = [Tools getHeightOfString:@"fds" fontSize:14 andWidth:999.9];
    
    CGFloat overflowHeight = [Tools getHeightOfString:[Tools routesCityConvert:_supplyInfoM.supplyModel.rOUTESCITY] fontSize:14 andWidth:contentWidth] - oneLineHeight;
    if(overflowHeight > 0) {
        
        _ROUTES_CITY_Bottom.constant = _ROUTES_CITY_Bottom.constant + overflowHeight;
        _supplyInfoViewHeight.constant = _supplyInfoViewHeight.constant + overflowHeight;
    }
    /*************  路线城市换行  *************/
    
    
    
    /*************  地址信息换行  *************/
    // tableView 总高度
    CGFloat tableViewHeight = 0;
    for (int i = 0; i < _supplyInfoM.routesModel.count; i++) {
        
        RoutesModel *routeM = _supplyInfoM.routesModel[i];
        
        // Label 容器宽度
        CGFloat contentWidth = ScreenWidth - 8 - 51 - 5;
        // Label 单行高度
        CGFloat oneLineHeight = [Tools getHeightOfString:@"fds" fontSize:14 andWidth:999.9];
        
        NSString *address = [NSString stringWithFormat:@"%@（%@）", routeM.aDDRESSNAME, routeM.aDDRESSINFO];
        
        CGFloat overflowHeight = [Tools getHeightOfString:address fontSize:14 andWidth:contentWidth] - oneLineHeight;
        
        if(overflowHeight > 0) {
            
            routeM.cellHeight = kCellHeight + overflowHeight;
        } else {
            
            routeM.cellHeight = kCellHeight;
        }
        tableViewHeight += routeM.cellHeight;
    }
    /*************  地址信息换行  *************/
    
    
    if(_showBidButtons) {
        
        _buttonsViewHeight.constant = 265;
    } else {
        
        _buttonsViewHeight.constant = 0;
        [_buttonsView setHidden:YES];
    }
    
    // 提示 + 竞标信息 + 提示 + 基本信息 + 提示 + 路线信息 + 竞标按钮容器高度
    _scrollContentViewHeight.constant = _bidInfoPromptViewHeight.constant + _bidInfoViewHeight.constant + _supplyInfoPromptViewHeight.constant + _supplyInfoViewHeight.constant + _routesPromptViewHeight.constant + tableViewHeight + _buttonsViewHeight.constant;
    
    [_tableView reloadData];
}


- (void)failureOfSupplyInfo:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
}


- (void)successOfReceivingSupply:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSupplyListVC_refreshNetworkData_Notification object:nil];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(1500000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}


- (void)failureOfReceivingSupply:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
}

@end
