//
//  AddDriverViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/2/23.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "AddDriverViewController.h"
#import "AddDriverService.h"
#import "Tools.h"
#import <RadioButton.h>
#import "LoginTextFieId.h"
#import "UserModel.h"
#import <MBProgressHUD.h>
#import "IB_UIView.h"

@interface AddDriverViewController ()<UITextFieldDelegate, AddDriverServiceDelegate> {
    
    AppDelegate *_app;
}


#define kvo_enabled @"enabled"

// contentView高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentViewHeight;

// 搜索View 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewHeight;

// 搜索结果View 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchResultViewHeight;

// 被添加的id 或 手机号码
@property (weak, nonatomic) IBOutlet LoginTextFieId *idOrPhoneNumF;

// 被添加的id 或 手机号码 底部样式
@property (weak, nonatomic) IBOutlet IB_UIView *textF_bg;

// 添加按钮
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;

// 司机详情视图
@property (weak, nonatomic) IBOutlet UIView *driverInfoView;

// 姓名
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

// 地址
@property (weak, nonatomic) IBOutlet UILabel *ADDRESS;

// 搜索结果
@property (strong, nonatomic) UserModel *userModel;

// 网络层
@property (strong, nonatomic) AddDriverService *service;

@property (assign, nonatomic) BOOL requestNetWorkComplete;

@end

@implementation AddDriverViewController

#pragma mark - 生命周期

- (instancetype)init {
    
    if(self = [super init]) {
        
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _service = [[AddDriverService alloc] init];
        _service.delegate = self;
        _requestNetWorkComplete = NO;
    }
    return self;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"添加司机";
    LMLog(@"viewDidLoad");
    
    [_idOrPhoneNumF setTextColor:[UIColor blackColor]];
    
    _searchBtn.backgroundColor = [UIColor clearColor];
    [_searchBtn setBackgroundImage:[self unEnableImage] forState:UIControlStateNormal];
    
    _textF_bg.layer.borderWidth = 1.0;
    _textF_bg.layer.borderColor = [UIColor grayColor].CGColor;
    _textF_bg.layer.cornerRadius = 2;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [_idOrPhoneNumF becomeFirstResponder];
}

- (void)updateViewConstraints {
    
    [super updateViewConstraints];
    
    _scrollContentViewHeight.constant = _searchViewHeight.constant + _searchResultViewHeight.constant;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
    
    LMLog(@"dealloc");
}


#pragma mark - 功能方法

- (UIImage *)enableImage {
    
    UIColor *color = CMColor;
    return [Tools createImageWithColor:color];
}


- (UIImage *)unEnableImage {
    
    UIColor *color = RGB(177, 177, 177);
    return [Tools createImageWithColor:color];
}


// 0.5秒内请求成功则不显示HUD
- (void)MBProgressHUDshowHUD {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(500000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(!_requestNetWorkComplete) {
                
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            }
        });
    });
}


#pragma mark - 事件

- (IBAction)textFieldDidChange:(LoginTextFieId *)sender {
    
    if (_idOrPhoneNumF.text.length > 11) {
        _idOrPhoneNumF.text = [_idOrPhoneNumF.text substringToIndex:11];
    }
    
    if(_idOrPhoneNumF.text.length > 0) {
//        [_searchBtn setEnabled:YES];
        [_searchBtn setBackgroundImage:[self enableImage] forState:UIControlStateNormal];
    } else {
//        [_searchBtn setEnabled:NO];
        [_searchBtn setBackgroundImage:[self unEnableImage] forState:UIControlStateNormal];
    }
}


- (IBAction)searchDriver:(UIButton *)sender {
    
    _requestNetWorkComplete = NO;
    if([_idOrPhoneNumF.textTrim isEqualToString:@""]) {
        
        [_idOrPhoneNumF becomeFirstResponder];
        return;
    }
    [self.view endEditing:YES];
    [self MBProgressHUDshowHUD];
    [_service GetDriverInfo:_idOrPhoneNumF.textTrim];
}


- (IBAction)commitOnclick:(UIButton *)sender {
    
    _requestNetWorkComplete = NO;
    [self.view endEditing:YES];
    [self MBProgressHUDshowHUD];
    [_service addDriver:_app.user.iDX andFLEET_IDX:_fleetIdx andADD_USER_IDX:_userModel.iDX];
}


#pragma mark - AddDriverServiceDelegate

- (void)successOfGetDriverInfo:(UserModel *)userModel {
    
    _requestNetWorkComplete = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [_driverInfoView setHidden:NO];
    
    _userModel = userModel;
    _ADDRESS.text = _userModel.aDDRESS;
    _nameLabel.text = _userModel.uSERNAME;
}


- (void)failureOfGetDriverInfo:(NSString *)msg {
    
    _requestNetWorkComplete = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [_driverInfoView setHidden:YES];
    [Tools showAlert:self.view andTitle:msg];
}


- (void)successOfAddDriver {
    
    _requestNetWorkComplete = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:@"添加成功"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDriverListVC_RequestNetWorkData_Notification object:nil];
}


- (void)failureOfAddDriver:(NSString *)msg {
    
    _requestNetWorkComplete = YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
}

@end
