//
//  CreateSupplyService.m
//  CMDriver
//
//  Created by 凯东源 on 17/5/3.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "CreateSupplyService.h"
#import <AFNetworking.h>

@implementation CreateSupplyService


#define kAPIName_GetTmsOrgList @"获取公司列表"

#define kAPIName_GetItemList @"请求车辆类型、尺寸"

#define kAPIName_CreateSupply @"创建货源"


#pragma mark - 获取公司列表

- (void)GetTmsOrgList:(NSString *)UserID {
    
    UserID = UserID ? UserID : @"";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    NSDictionary *parameters = @{@"UserID" : UserID,
                                 @"strLicense" : @""
                                 };
    
    LMLog(@"请求%@参数:%@", kAPIName_GetTmsOrgList, parameters);
    
    [manager POST:API_GetTmsOrgList parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LMLog(@"%@,请求成功,返回值:%@", kAPIName_GetTmsOrgList, responseObject);
        NSInteger type = [responseObject[@"type"] intValue];
        NSString *msg = responseObject[@"msg"];
        
        if(type == 1) {
            
            NSDictionary *result = responseObject[@"result"];
            
            NSString *ORG_IDX = result[@"ORG_IDX"];
            
            NSArray *tms = [ORG_IDX componentsSeparatedByString:@","];
            
            NSMutableArray *arrM = [tms mutableCopy];
            [arrM insertObject:kAllTmsOrgList atIndex:0];
            NSArray *TmsOrgList = [arrM copy];
            
            [self successOfGetTmsOrgList:TmsOrgList];
            
            LMLog(@"%@成功，msg:%@", kAPIName_GetTmsOrgList, msg);
        } else if(type == 0) {
            
            [self failureOfGetTmsOrgList:msg];
        } else {
            
            [self failureOfGetTmsOrgList:msg];
            LMLog(@"%@返回值异常，type:%ld,msg:%@", kAPIName_GetTmsOrgList, (long)type, msg);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self failureOfGetTmsOrgList:@"请求失败"];
        LMLog(@"%@时，请求失败，error:%@", kAPIName_GetTmsOrgList, error);
    }];
}


#pragma mark - 获取车辆尺寸/类型

- (void)GetItemLis:(NSString *)UserID {
    
    UserID = UserID ? UserID : @"";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    NSDictionary *parameters = @{@"UserID" : UserID,
                                 @"strLicense" : @""
                                 };
    
    LMLog(@"请求%@参数:%@", kAPIName_GetItemList, parameters);
    
    [manager POST:API_GetItemList parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LMLog(@"%@,请求成功,返回值:%@", kAPIName_GetItemList, responseObject);
        NSInteger type = [responseObject[@"type"] intValue];
        NSString *msg = responseObject[@"msg"];
        
        if(type == 1) {
            
            GetItemListModel *item = [[GetItemListModel alloc] init];
            
            NSString *SupplyType = responseObject[@"result"][@"SupplyType"];
            NSArray *SupplyTypeArray = [SupplyType componentsSeparatedByString:@","];
            NSMutableArray *arrM = [SupplyTypeArray mutableCopy];
            [arrM insertObject:kAllSupplyType atIndex:0];
            item.supplyType = [arrM copy];
            
            NSString *VehicleSize = responseObject[@"result"][@"VehicleSize"];
            NSArray *VehicleSizeArray = [VehicleSize componentsSeparatedByString:@","];
            arrM = [VehicleSizeArray mutableCopy];
            [arrM insertObject:kAllVehicleSize atIndex:0];
            item.vehicleSize = [arrM copy];
            
            NSString *VehicleType = responseObject[@"result"][@"VehicleType"];
            NSArray *VehicleTypeArray = [VehicleType componentsSeparatedByString:@","];
            arrM = [VehicleTypeArray mutableCopy];
            [arrM insertObject:kAllVehicleType atIndex:0];
            item.vehicleType = [arrM copy];
            
            [self successOfGetItemList:item];
            
            LMLog(@"%@成功，msg:%@", kAPIName_GetItemList, msg);
        } else if(type == 0) {
            
            [self failureOfGetItemList:msg];
        } else {
            
            [self failureOfGetItemList:msg];
            LMLog(@"%@返回值异常，type:%ld,msg:%@", kAPIName_GetItemList, (long)type, msg);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self failureOfGetItemList:@"请求失败"];
        LMLog(@"%@时，请求失败，error:%@", kAPIName_GetItemList, error);
    }];
}


#pragma mark - 创建货源

- (void)CreateSupply:(NSDictionary *)dict {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    LMLog(@"请求%@参数:%@", kAPIName_CreateSupply, dict);
    
    [manager POST:API_UpDate_SUPPLY_Detail parameters:dict progress:^(NSProgress * _Nonnull uploadProgress) {
        nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LMLog(@"%@,请求成功,返回值:%@", kAPIName_CreateSupply, responseObject);
        NSInteger type = [responseObject[@"type"] intValue];
        NSString *msg = responseObject[@"msg"];
        
        if(type == 1) {
            
            [self successOfCreateSupply:msg];
            LMLog(@"%@成功，msg:%@", kAPIName_CreateSupply, msg);
        } else if(type == 0) {
            
            [self failureOfCreateSupply:msg];
        } else {
            
            [self failureOfCreateSupply:msg];
            LMLog(@"%@返回值异常，type:%ld,msg:%@", kAPIName_CreateSupply, (long)type, msg);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self failureOfCreateSupply:@"请求失败"];
        LMLog(@"%@时，请求失败，error:%@", kAPIName_CreateSupply, error);
    }];
}


#pragma mark - 功能函数

// 获取公司列表
- (void)successOfGetTmsOrgList:(NSArray *)TmsOrgList{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(successOfGetTmsOrgList:)]) {
            [_delegate successOfGetTmsOrgList:TmsOrgList];
        }
    });
}


- (void)failureOfGetTmsOrgList:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(failureOfGetTmsOrgList:)]) {
            [_delegate failureOfGetTmsOrgList:msg];
        }
    });
}


// 获取车辆类型/尺寸
- (void)successOfGetItemList:(GetItemListModel *)itemListM{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(successOfGetItemList:)]) {
            [_delegate successOfGetItemList:itemListM];
        }
    });
}


- (void)failureOfGetItemList:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(failureOfGetItemList:)]) {
            [_delegate failureOfGetItemList:msg];
        }
    });
}


// 创建货源
- (void)successOfCreateSupply:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(successOfCreateSupply:)]) {
            [_delegate successOfCreateSupply:msg];
        }
    });
}


- (void)failureOfCreateSupply:(NSString *)msg {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([_delegate respondsToSelector:@selector(failureOfCreateSupply:)]) {
            [_delegate failureOfCreateSupply:msg];
        }
    });
}

@end
