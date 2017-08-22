//
//  DriverPayViewController.m
//  CMDriver
//
//  Created by 凯东源 on 17/3/11.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "DriverPayViewController.h"
#import "LM_alert.h"
#import "Tools.h"
#import "AutoGraphView.h"
#import "DriverPayService.h"
#import <MBProgressHUD.h>
#import "ZYInfoViewController.h"


@interface DriverPayViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, DriverPayServiceDelegate,UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    
    UIImagePickerController *pickerController;
}

// 卸货车照按钮
@property (weak, nonatomic) IBOutlet UIButton *unLoadBtn;

// 回单照片按钮
@property (weak, nonatomic) IBOutlet UIButton *receiptBtn;

// 卸货车照
@property (strong, nonatomic) UIImage *unLoadImage;

// 回单照片
@property (strong, nonatomic) UIImage *receiptImage;

// 谁在使用相机 0卸货  1回单
@property (assign, nonatomic) int whoUseCamera;

// 签名
@property (weak, nonatomic) IBOutlet AutoGraphView *autoGraphView;

// 网络层
@property (strong, nonatomic) DriverPayService *service;

// scrollContentView 高度
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentViewHeight;

@end


@implementation DriverPayViewController

typedef enum
{
    unLoad = 0,
    receipt
    
} WhoUseCamera;


#pragma mark - 生命周期

- (instancetype)init {
    
    if(self = [super init]) {
        
        _service = [[DriverPayService alloc] init];
        _service.delegate = self;
    }
    return self;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"订单交付";
    
    [self createData];
    
    _scrollContentViewHeight.constant = ScreenHeight - 20 - 44;
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - 相机

- (void)addPicture {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"相册",@"图库",nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}


- (void)createData {
    
    // 初始化pickerController
    pickerController = [[UIImagePickerController alloc] init];
    pickerController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    pickerController.delegate = self;
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


#pragma mark - 事件

// 添加 或 查看卸货车照
- (IBAction)addOrShowUnLoadPictureOnclik:(UIButton *)sender {
    
    _whoUseCamera = 0;
    
    [self addPicture];
}


// 添加 或 查看回单照片
- (IBAction)addOrShowReceiptPictureOnclick:(UIButton *)sender {
    
    _whoUseCamera = 1;
    
    [self addPicture];
}


// 清空签名
- (IBAction)reSetAutoGraphView:(id)sender {
    
    [_autoGraphView clear];
}


- (IBAction)cancelOnclick:(UIButton *)sender {
    
}


- (IBAction)commitOnclick:(UIButton *)sender {
    
    if(!_unLoadImage) {
        
        [Tools showAlert:self.view andTitle:@"请拍摄卸货照"];
        return;
    }
    
    if(!_receiptImage) {
        
        [Tools showAlert:self.view andTitle:@"请拍摄回单照片"];
        return;
    }
    
    if(_autoGraphView.allLine.count == 0) {
        
        [Tools showAlert:self.view andTitle:@"请签名"];
        return;
    }
    
    UIImage *autoGraphImage = [Tools convertViewToImage:_autoGraphView];
    
    NSString *autoGraphImageString = [Tools convertImageToString:autoGraphImage];
    NSString *unLoadImageString = [Tools convertImageToString:_unLoadImage];
    NSString *receiptImageString = [Tools convertImageToString:_receiptImage];
    
//    autoGraphImageString = [autoGraphImageString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
//    unLoadImageString = [unLoadImageString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
//    receiptImageString = [receiptImageString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    [_service DriverPay:_orderIdx andPictureFile1:unLoadImageString andPictureFile2:receiptImageString andAutographFile:autoGraphImageString];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}


#pragma mark - 功能函数

//pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
//[self presentViewController:pickerController animated:YES completion:nil];

//- (void)addPicture {
//    
//    [LM_alert showLMAlertViewWithTitle:@"拍照上传" message:@"" cancleButtonTitle:@"取消" okButtonTitle:@"确定" okClickHandle:^{
//        
//        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//            
//            UIImagePickerController *picker =  [[UIImagePickerController alloc] init];
//            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//            //            picker.mediaTypes = @[kCIAttributeTypeImage];
//            picker.delegate = self;
//            picker.allowsEditing = NO;
//            [self presentViewController:picker animated:YES completion:nil];
//        } else {
//            
//            [Tools showAlert:self.view andTitle:@"相机功能不可用"];
//        }
//    } cancelClickHandle:^{
//        
//    }];
//}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    if(!image) {
        
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    if(image) {
        
        NSData *data = [Tools compressImage:image andMaxLength:1024*100 andMaxWidthAndHeight:350];
        
        if(data) {
            
            image = [UIImage imageWithData:data];
        }
    }
    
    switch (_whoUseCamera) {
            
        case 0:
            [_unLoadBtn setImage:image forState:UIControlStateNormal];
            _unLoadImage = image;
            break;
            
        case 1:
            [_receiptBtn setImage:image forState:UIControlStateNormal];
            _receiptImage = image;
            break;
            
        default:
            break;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.view endEditing:YES];
    return YES;
}


#pragma mark - DriverPayServiceDelegate

- (void)successOfDriverPay {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:@"交付成功"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        // 延迟pop
        usleep(1300000);
        dispatch_async(dispatch_get_main_queue(), ^{
           
            // 找到nav上两层 并pop
            ZYInfoViewController *zyVC = nil;
            for (int i = 0; i < self.navigationController.viewControllers.count; i++) {
                
                UIViewController *vc = self.navigationController.viewControllers[i];
                if([vc isKindOfClass:[ZYInfoViewController class]]) {
                    
                    zyVC = (ZYInfoViewController *)vc;
                }
            }
            [self.navigationController popToViewController:zyVC animated:YES];
        });
    });
}


- (void)failureOfDriverPay:(NSString *)msg {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [Tools showAlert:self.view andTitle:msg];
}

@end
