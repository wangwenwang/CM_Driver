//
//  SupplyInfoViewController.h
//  CMDriver
//
//  Created by 凯东源 on 17/3/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SupplyInfoViewController : UIViewController


/// 货源ID
@property (nonatomic, copy) NSString *supplyIdx;

/// 是否要显示竞标按钮
@property (nonatomic, assign) BOOL showBidButtons;

@end
