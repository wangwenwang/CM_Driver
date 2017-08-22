//
//  FleetListTableViewCell.m
//  CMDriver
//
//  Created by 凯东源 on 17/3/3.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "FleetListTableViewCell.h"

@interface FleetListTableViewCell ()

// 车队队长
@property (weak, nonatomic) IBOutlet UILabel *CONTACT_PERSON;

// 边框样式
@property (weak, nonatomic) IBOutlet UIView *cellFrameView;

@end

@implementation FleetListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setFleetM:(FleetModel *)fleetM {
    
    _fleetM = fleetM;
    
    _fleetNameLabel.text = fleetM.fLEETNAME;
    _companyNameLabel.text = fleetM.tMSNAME;
    _comtactTelLabel.text = fleetM.cONTACTTEL;
    
    if([fleetM.fLEETPROPERTY isEqualToString:@"COMPANY"]) {
        
        _fleetNameLabel.textColor = CMColor;
    } else if([fleetM.fLEETPROPERTY isEqualToString:@"INDIVIDUAL"]) {
        
        _fleetNameLabel.textColor = RGB(117, 183, 82);
    } else {
        
        _fleetNameLabel.textColor = [UIColor blackColor];
    }
    
    _CONTACT_PERSON.text = _fleetM.cONTACTPERSON;
    
    _cellFrameView.layer.cornerRadius = 6.0f;
    _cellFrameView.layer.borderWidth = 1.0;
    _cellFrameView.layer.borderColor = RGB(197, 197, 197).CGColor;
}

@end
