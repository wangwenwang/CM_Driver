//
//  SupplyListTableViewCell.h
//  CMClient
//
//  Created by 凯东源 on 17/3/4.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SupplyListModel.h"

@interface SupplyListTableViewCell : UITableViewCell

@property (strong, nonatomic) SupplyListModel *supplyListM;

@property (assign, nonatomic) BOOL SUPPLY_STATE_Image_nil;

@end
