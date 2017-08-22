//
//  TruckModel.h
//  CMDriver
//
//  Created by 凯东源 on 17/3/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import <Foundation/Foundation.h>


//{
//    "VEHICLE_SIZE" : "5.2M",
//    "PLATE_NUMBER" : "粤B3412",
//    "BRAND_MODEL" : "逸动 2016劲尚版 手动1.5L",
//    "VEHICLE_MODEL" : "常温车",
//    "IDX" : "95"
//}


@interface TruckModel : NSObject

@property (nonatomic, strong) NSString * bRANDMODEL;
@property (nonatomic, strong) NSString * iDX;
@property (nonatomic, strong) NSString * pLATENUMBER;
@property (nonatomic, strong) NSString * vEHICLEMODEL;
@property (nonatomic, strong) NSString * vEHICLESIZE;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

-(NSDictionary *)toDictionary;

@end
