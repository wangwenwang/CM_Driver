//
//  AddTruckViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/3/2.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "AddTruckViewController.h"
#import "AddTruckServer.h"
#import "Tools.h"
#import "AddFleetTextField.h"
#import "AddFleetButton.h"
#import <MBProgressHUD.h>
#import "CreateSupplyService.h"
#import "PhotoBroswerVC.h"
#import "LM_alert.h"
#import "TruckDetailService.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface AddTruckViewController ()<AddTruckServerDelegate, CreateSupplyServiceDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    AppDelegate *_app;
    UIImagePickerController *pickerController;
}

// 车牌号
@property (weak, nonatomic) IBOutlet AddFleetTextField *plateNumberF;

// 车辆类型
@property (weak, nonatomic) IBOutlet AddFleetTextField *vehicleModelF;

// 车辆尺寸
@property (weak, nonatomic) IBOutlet AddFleetTextField *vehicleSizeF;

// 品牌型号
@property (weak, nonatomic) IBOutlet AddFleetTextField *brandModelF;

// 车辆颜色
@property (weak, nonatomic) IBOutlet AddFleetTextField *vehicleColorF;

// 最大载重量
@property (weak, nonatomic) IBOutlet AddFleetTextField *maxWeightF;

// 最大装载量
@property (weak, nonatomic) IBOutlet AddFleetTextField *maxVolumeF;

// 提交按钮
@property (weak, nonatomic) IBOutlet AddFleetButton *commitBtn;

// 网络请求服务
@property (strong, nonatomic) AddTruckServer *service;

@property (strong, nonatomic) CreateSupplyService *service_createSupply;

// 车辆类型、尺寸
@property (strong, nonatomic) GetItemListModel *itemListM;

// scrollContentView 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentViewHeight;

// 驾驶证正面
@property (weak, nonatomic) IBOutlet UIImageView *drivingLicense_forword_imageView;

@property (weak, nonatomic) IBOutlet UIView *drivingLicense_forword_view;

@property (weak, nonatomic) IBOutlet UIView *drivingLicense_back_view;

@property (weak, nonatomic) IBOutlet UIView *truck_header_view;

// 驾驶证副页
@property (weak, nonatomic) IBOutlet UIImageView *drivingLicense_back_imageView;

// 车头照片
@property (weak, nonatomic) IBOutlet UIImageView *truck_header_imageView;

// 当前图片类型
@property (assign, nonatomic) NSUInteger currentPictureType;

// 删除驾驶证正面
@property (weak, nonatomic) IBOutlet UIButton *drivingLicense_forword_deleteBtn;

// 删除驾驶证副页
@property (weak, nonatomic) IBOutlet UIButton *drivingLicense_bak_deleteBtn;

// 删除车头照片
@property (weak, nonatomic) IBOutlet UIButton *truck_header_deleteBtn;

// 图片容器
@property (weak, nonatomic) IBOutlet UIView *PictureContainer;

// 遮罩
@property (weak, nonatomic) IBOutlet UIView *coverView;

// 搜索
@property (weak, nonatomic) IBOutlet UIView *searchView;

// 车牌号
@property (weak, nonatomic) IBOutlet UITextField *plateT;

// 车辆详情
@property (nonatomic, strong) TruckDetailModel *truckDetailM;

// 车辆详情网络层
@property (nonatomic, strong) TruckDetailService *service_truckDetial;

@end


#define KVO_TAG @"tag"


// 照片类型
typedef enum _PictureType {
    
    Picture_TYPE_drivingLicense_forword  = 0,       // 驾驶证正面
    Picture_TYPE_drivingLicense_back,               // 驾驶证副页
    Picture_TYPE_truck_header                       // 车头照片
} PictureType;

@implementation AddTruckViewController


#pragma mark - 生命周期

- (instancetype)init {
    if(self = [super init]) {
        
        _service = [[AddTruckServer alloc] init];
        _service.delegate = self;
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _service_createSupply = [[CreateSupplyService alloc] init];
        _service_createSupply.delegate = self;
        _service_truckDetial = [[TruckDetailService alloc] init];
        _service_truckDetial.delegate = self;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"添加车辆";
    
    [self createData];
    
    [self addKVO];
    
    _plateNumberF.labelText = @"车牌号";
    _vehicleModelF.labelText = @"车辆类型";
    _vehicleSizeF.labelText = @"车辆尺寸";
    _brandModelF.labelText = @"品牌型号";
    _vehicleColorF.labelText = @"车辆颜色";
    _maxWeightF.labelText = @"最大载重量(吨)";
    _maxVolumeF.labelText = @"最大装载量(m³)";
    
    [_service_createSupply GetItemLis:@""];
    
    [_plateT becomeFirstResponder];
    
    [Tools addNavRightItemTypeText:self andAction:@selector(searchTruck) andTitle:@"搜索"];
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    _scrollContentViewHeight.constant = CGRectGetMaxY(_commitBtn.frame) + 20;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
    
    [self removeKVO];
}


#pragma mark - 功能函数

- (void)addKVO {
    
    [_drivingLicense_forword_imageView addObserver:self forKeyPath:KVO_TAG options:NSKeyValueObservingOptionNew context:nil];
    [_drivingLicense_back_imageView addObserver:self forKeyPath:KVO_TAG options:NSKeyValueObservingOptionNew context:nil];
    [_truck_header_imageView addObserver:self forKeyPath:KVO_TAG options:NSKeyValueObservingOptionNew context:nil];
}


- (void)removeKVO {
    
    [_drivingLicense_forword_imageView removeObserver:self forKeyPath:KVO_TAG];
    [_drivingLicense_back_imageView removeObserver:self forKeyPath:KVO_TAG];
    [_truck_header_imageView removeObserver:self forKeyPath:KVO_TAG];
}


- (void)searchTruck {
    
    [_searchView setHidden:NO];
    [_coverView setHidden:NO];

    [Tools addAnimation:_searchView andDuration:0.15];
    [Tools addAnimation:_coverView andDuration:0.15];
    
    [_plateT becomeFirstResponder];
}


#pragma mark - 照片

- (void)createData {
    
    // 初始化pickerController
    pickerController = [[UIImagePickerController alloc] init];
    pickerController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    pickerController.delegate = self;
//    pickerController.allowsEditing = YES;
}


// 跳转到imagePicker里
- (void)makePhoto {
    
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:pickerController animated:YES completion:nil];
}


// 跳转到相册
- (void)choosePicture {
    
    pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:pickerController animated:YES completion:nil];
}


// 跳转图库
- (void)pictureLibrary {
    
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:pickerController animated:YES completion:nil];
}


- (void)addPicture {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"相册",@"图库",nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


#pragma mark - 手势

// 车辆类型
- (IBAction)Vehicle_Model_Onclick:(UITapGestureRecognizer *)sender {
    
    [self.view endEditing:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"车辆类型" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
    alert.tag = 1001;
    
    for ( int i = 0; i < _itemListM.vehicleType.count; i++) {
        
        [alert addButtonWithTitle:_itemListM.vehicleType[i]];
    }
    
    alert.delegate = self;
    
    [alert show];
}


// 车辆尺寸
- (IBAction)Vehicle_Size_Onclick:(id)sender {
    
    [self.view endEditing:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"车辆尺寸" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
    alert.tag = 1002;
    
    for ( int i = 0; i < _itemListM.vehicleSize.count; i++) {
        
        [alert addButtonWithTitle:_itemListM.vehicleSize[i]];
    }
    
    alert.delegate = self;
    
    [alert show];
}


- (void)checkPicture:(UIImage *)image andIndex:(NSUInteger)index {
    
    [PhotoBroswerVC show:self type:PhotoBroswerVCTypeZoom index:0 photoModelBlock:^NSArray *{
        
        NSArray *localImages = @[image];
        
        NSMutableArray *modelsM = [NSMutableArray arrayWithCapacity:localImages.count];
        for (NSUInteger i = 0; i< localImages.count; i++) {
            
            PhotoModel *pbModel=[[PhotoModel alloc] init];
            pbModel.mid = i + 1;
            pbModel.image = localImages[i];
            
            //源frame
            UIImageView *imageV = (UIImageView *) _PictureContainer.subviews[i];
            switch (index) {
                    
                case Picture_TYPE_drivingLicense_forword:
                    imageV = (UIImageView *)_drivingLicense_forword_view.subviews[0];
                    break;
                    
                case Picture_TYPE_drivingLicense_back:
                    imageV = (UIImageView *)_drivingLicense_back_view.subviews[0];
                    break;
                    
                case Picture_TYPE_truck_header:
                    imageV = (UIImageView *)_truck_header_view.subviews[0];
                    break;
                    
                default:
                    break;
            }
            
            pbModel.sourceImageView = imageV;
            
            [modelsM addObject:pbModel];
        }
        
        return modelsM;
    }];
}


// 驾驶证正面
- (IBAction)drivingLicense_forword_Onclick:(UITapGestureRecognizer *)sender {
    
    [self.view endEditing:YES];
    
    if(_drivingLicense_forword_imageView.tag) {
        
        [self checkPicture:_drivingLicense_forword_imageView.image andIndex:0];
    } else {
        
        _currentPictureType = Picture_TYPE_drivingLicense_forword;
        [self addPicture];
    }
}


// 驾驶证副页
- (IBAction)drivingLicense_back_Onclick:(UITapGestureRecognizer *)sender {
    
    [self.view endEditing:YES];
    
    if(_drivingLicense_back_imageView.tag) {
        
        [self checkPicture:_drivingLicense_back_imageView.image andIndex:1];
    } else {
        
        _currentPictureType = Picture_TYPE_drivingLicense_back;
        [self addPicture];
    }
}


// 车头照片
- (IBAction)truck_header_Onclick:(UITapGestureRecognizer *)sender {
    
    [self.view endEditing:YES];
    
    if(_truck_header_imageView.tag) {
        
        [self checkPicture:_truck_header_imageView.image andIndex:2];
    } else {
        
        _currentPictureType = Picture_TYPE_truck_header;
        [self addPicture];
    }
}


#pragma mark - 事件

- (IBAction)commitOnclick:(UIButton *)sender {
    
    [self.view endEditing:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(500000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([_maxWeightF isPureFloat] || [_maxWeightF.textTrim isEqualToString:@""]) {
                if([_maxVolumeF isPureFloat] || [_maxVolumeF.textTrim isEqualToString:@""]) {
                    
                    NSString *w1 = [Tools convertImageToString:_drivingLicense_forword_imageView.image];
                    NSString *w2 = [Tools convertImageToString:_drivingLicense_back_imageView.image];
                    NSString *w3 = [Tools convertImageToString:_truck_header_imageView.image];
                    
                    [_service addTruck:_app.user.iDX andFLEET_ID:_fleetIdx andPLATE_NUMBER:_plateNumberF.textTrim andVEHICLE_MODEL:_vehicleModelF.textTrim andVEHICLE_SIZE:_vehicleSizeF.textTrim andBRAND_MODEL:_brandModelF.textTrim andVEHICLE_COLOR:_vehicleColorF.textTrim andMAX_WEIGHT:[_maxWeightF.textTrim floatValue] andMAX_VOLUME:[_maxVolumeF.textTrim floatValue] andPictureFile1:w1 andPictureFile2:w2 andAutographFile:w3];
                    
                    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                } else {
                    
                    [Tools showAlert:self.view andTitle:@"最大装载量不合法，只能输入数字"];
                }
            } else {
                
                [Tools showAlert:self.view andTitle:@"最大载重不合法，只能输入数字"];
            }
        });
    });
}


- (IBAction)textChanged:(UITextField *)sender {
    
    if([_plateNumberF.textTrim isEqualToString:@""]) {
        
        [_commitBtn setEnabled:NO];
        
    } else {
        
        [_commitBtn setEnabled:YES];
    }
}


// 删除图片
- (IBAction)deletePicture:(UIButton *)sender {
    
    _currentPictureType = sender.tag;
    
    [LM_alert showLMAlertViewWithTitle:@"" message:@"真的的删除此照片吗？" cancleButtonTitle:@"取消" okButtonTitle:@"确定" okClickHandle:^{
        switch (sender.tag) {
                
            case Picture_TYPE_drivingLicense_forword:
                
                _drivingLicense_forword_imageView.image = [UIImage imageNamed:@"truck_drivingLicense_forword_prompt"];
                _drivingLicense_forword_imageView.tag = 0;
                break;
                
            case Picture_TYPE_drivingLicense_back:
                
                _drivingLicense_back_imageView.image = [UIImage imageNamed:@"truck_drivingLicense_back_prompt"];
                _drivingLicense_back_imageView.tag = 0;
                break;
                
            case Picture_TYPE_truck_header:
                
                _truck_header_imageView.image = [UIImage imageNamed:@"truck_header_prompt"];
                _truck_header_imageView.tag = 0;
                break;
                
            default:
                break;
        }
    } cancelClickHandle:nil];
}


- (IBAction)createOnclick:(UIButton *)sender {
    
    [_searchView setHidden:YES];
    [_coverView setHidden:YES];
    
    [Tools addAnimation:_searchView andDuration:0.15];
    [Tools addAnimation:_coverView andDuration:0.15];
    
    [self.view endEditing:YES];
}


- (IBAction)confirmSearchOnclick:(UIButton *)sender {
    
    if([_plateT.textTrim isEqualToString:@""]) {
        
        [Tools showAlert:self.view andTitle:@"请填写车牌号"];
        return;
    }

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [_service_truckDetial SearchVehicle:_plateT.text andstrFleetIdx:@""];
}


#pragma mark - CreateSupplyServiceDelegate

- (void)successOfGetItemList:(GetItemListModel *)itemListM {
    
    _itemListM = itemListM;
    
    NSMutableArray *vehicleTypeList = [itemListM.vehicleType mutableCopy];
    for(int i = 0; i < vehicleTypeList.count; i++) {
        
        if([vehicleTypeList[i] isEqualToString:kAllVehicleType]) {
            
            vehicleTypeList[i] = @"没有相应类型？填写";
        }
    }
    _itemListM.vehicleType = [vehicleTypeList copy];
    
    NSMutableArray *vehicleSizeList = [itemListM.vehicleSize mutableCopy];
    for(int i = 0; i < vehicleSizeList.count; i++) {
        
        if([vehicleSizeList[i] isEqualToString:kAllVehicleSize]) {
            
            vehicleSizeList[i] = @"没有相应尺寸？填写";
        }
    }
    _itemListM.vehicleSize = [vehicleSizeList copy];
}


- (void)failureOfGetItemList:(NSString *)msg {
    
    [Tools showAlert:self.view andTitle:msg];
}


#pragma mark - AddTruckServerDelegate

- (void)successOfAddTruck {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTruckListVC_RequestNetWorkData_Notification object:nil];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [Tools showAlert:self.view andTitle:@"添加成功"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        usleep(250000);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}


- (void)failureOfAddTruck:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [Tools showAlert:self.view andTitle:msg];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSLog(@"buttonIndex:%ld", (long)buttonIndex);
    
    if(buttonIndex == 0) {
        
        nil;  //点击取消， 不操作
    } else if(buttonIndex == 1) {
        
        if(alertView.tag == 1001) { // 车辆类型
            
            [_vehicleModelF setEnabled:YES];
            [_vehicleModelF becomeFirstResponder];
        } else if(alertView.tag == 1002) { // 车辆尺寸
            
            [_vehicleSizeF setEnabled:YES];
            [_vehicleSizeF becomeFirstResponder];
        }
    } else {
        
        if(alertView.tag == 1001) { // 车辆类型
            
            _vehicleModelF.text = _itemListM.vehicleType[buttonIndex - 1];
        } else if(alertView.tag == 1002) { // 车辆尺寸
            
            _vehicleSizeF.text = _itemListM.vehicleSize[buttonIndex - 1];
        }
    }
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {//相机
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            
            NSLog(@"支持相机");
            [self makePhoto];
        } else {
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"message:@"请在设置-->隐私-->相机，中开启本应用的相机访问权限！！"delegate:self cancelButtonTitle:@"取消"otherButtonTitles:@"我知道了",nil];
            [alert show];
        }
    } else if (buttonIndex == 1) {//相片
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            
            NSLog(@"支持相册");
            [self choosePicture];
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"message:@"请在设置-->隐私-->照片，中开启本应用的相机访问权限！！"delegate:self cancelButtonTitle:@"取消"otherButtonTitles:@"我知道了",nil];
            [alert show];
        }
    } else if (buttonIndex == 2) {//图册
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            
            NSLog(@"支持图库");
            [self pictureLibrary];
        } else {
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"message:@"请在设置-->隐私-->照片，中开启本应用的相机访问权限！！"delegate:self cancelButtonTitle:@"取消"otherButtonTitles:@"我知道了",nil];
            [alert show];
        }
    }
}


#pragma mark - UIImagePickerControllerDelegate

// 用户选中图片之后的回调
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSLog(@"%s,info == %@",__func__,info);
    
    UIImage *userImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSData *b = [Tools compressImage:userImage andMaxLength:1024*100 andMaxWidthAndHeight:1000];
    
    switch (_currentPictureType) {
            
        case Picture_TYPE_drivingLicense_forword:
            
            _drivingLicense_forword_imageView.image = [UIImage imageWithData:b];
            _drivingLicense_forword_imageView.tag = 1;  // 代表已添加图片
            break;
            
        case Picture_TYPE_drivingLicense_back:
            
            _drivingLicense_back_imageView.image = [UIImage imageWithData:b];
            _drivingLicense_back_imageView.tag = 1;     // 代表已添加图片
            break;
            
        case Picture_TYPE_truck_header:
            
            _truck_header_imageView.image = [UIImage imageWithData:b];
            _truck_header_imageView.tag = 1;            // 代表已添加图片
            break;
            
        default:
            break;
    }
    
    [pickerController dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}


// 用户取消退出picker时候调用
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    NSLog(@"%@",picker);
    [pickerController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([object isKindOfClass:[UIImageView class]]  && [keyPath isEqualToString:KVO_TAG]) {
        
        NSUInteger old = [change[@"old"] integerValue];
        NSUInteger new = [change[@"new"] integerValue];
        NSLog(@"old:%lu, new:%lu", (unsigned long)old, (unsigned long)new);
        
        if(new == 1) {
            
            switch (_currentPictureType) {
                    
                case Picture_TYPE_drivingLicense_forword:
                    
                    [_drivingLicense_forword_deleteBtn setHidden:NO];
                    break;
                    
                case Picture_TYPE_drivingLicense_back:
                    
                    [_drivingLicense_bak_deleteBtn setHidden:NO];
                    break;
                    
                case Picture_TYPE_truck_header:
                    
                    [_truck_header_deleteBtn setHidden:NO];
                    break;
                    
                default:
                    break;
            }
        } else {
            
            switch (_currentPictureType) {
                    
                case Picture_TYPE_drivingLicense_forword:
                    
                    [_drivingLicense_forword_deleteBtn setHidden:YES];
                    break;
                    
                case Picture_TYPE_drivingLicense_back:
                    
                    [_drivingLicense_bak_deleteBtn setHidden:YES];
                    break;
                    
                case Picture_TYPE_truck_header:
                    
                    [_truck_header_deleteBtn setHidden:YES];
                    break;
                    
                default:
                    break;
            }
        }
        
        NSLog(@"new:%lu", (unsigned long)new);
    } else {
        
        
    }
}


#pragma mark - TruckDetailServiceDelegate

- (void)successOfTruckDetail:(TruckDetailModel *)truckDetailM {
    
    _truckDetailM = truckDetailM;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    _plateNumberF.text = _truckDetailM.pLATENUMBER;
    _vehicleModelF.text = _truckDetailM.vEHICLEMODEL;
    _vehicleSizeF.text = _truckDetailM.vEHICLESIZE;
    _brandModelF.text = _truckDetailM.bRANDMODEL;
    _vehicleColorF.text = _truckDetailM.vEHICLECOLOR;
    _maxWeightF.text = _truckDetailM.mAXWEIGHT;
    _maxVolumeF.text = _truckDetailM.mAXVOLUME;
    
    
    NSURL *path1 = [Tools getCompleteUrl:_truckDetailM.pictureFile1];
    
    NSURL *path2 = [Tools getCompleteUrl:_truckDetailM.pictureFile2];
    
    NSURL *path3 = [Tools getCompleteUrl:_truckDetailM.autographFile];
    
    if(![_truckDetailM.pictureFile1 isEqualToString:@""]) {
        
        UIImage *defaultImage = [UIImage imageNamed:@"truck_drivingLicense_forword_prompt"];
        [_drivingLicense_forword_imageView sd_setImageWithURL:path1 placeholderImage:defaultImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
    }
    
    if(![_truckDetailM.pictureFile2 isEqualToString:@""]) {
        
        UIImage *defaultImage = [UIImage imageNamed:@"truck_drivingLicense_back_prompt"];
        [_drivingLicense_back_imageView sd_setImageWithURL:path2 placeholderImage:defaultImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
    }
    
    if(![_truckDetailM.autographFile isEqualToString:@""]) {
        
        UIImage *defaultImage = [UIImage imageNamed:@"truck_header_prompt"];
        [_truck_header_imageView sd_setImageWithURL:path3 placeholderImage:defaultImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
    }
    
    [self createOnclick:nil];
    
    [_commitBtn setEnabled:YES];
}


- (void)failureOfTruckDetail:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.view endEditing:YES];
    
    [Tools showAlert:self.view andTitle:@"没有此车辆"];
}

@end
