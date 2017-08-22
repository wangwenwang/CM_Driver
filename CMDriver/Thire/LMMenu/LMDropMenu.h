//
//  LMDropMenu.h
//  downDropMenu
//
//  Created by 凯东源 on 17/6/4.
//  Copyright © 2017年 xx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataItemModel.h"

@interface LMIndexPath : NSObject

@property (nonatomic, assign) NSUInteger column;

@property (nonatomic, assign) NSUInteger row;

@end

#pragma mark - data source protocol

@class LMDropMenu;

@protocol LMDropDownMenuDataSource <NSObject>

@required
- (NSUInteger)menu:(LMDropMenu *)menu numberOfRowsInColumn:(NSUInteger)column;

- (DataItemModel *)menu:(LMDropMenu *)menu titleForRowAtIndexPath:(LMIndexPath *)indexPath;

- (NSString *)menu:(LMDropMenu *)menu titleForColumn:(NSInteger)column;

//default value is 1
- (NSInteger)numberOfColumnsInMenu:(LMDropMenu *)menu;

@end



#pragma mark - delegate

@protocol LMDropDownMenuDelegate <NSObject>

@optional
- (void)menu:(LMDropMenu *)menu didSelectRowAtIndexPath:(LMIndexPath *)indexPath;

//@property (nonatomic, weak) id <JSDropDownMenuDataSource> dataSource;

- (void)antiElectionOnclick;

- (void)filterComplete;

- (void)filterCancel;

- (void)menuTapped:(NSUInteger)touchIndex;

@end



@interface LMDropMenu : UIView

@property (nonatomic, weak) id <LMDropDownMenuDataSource> dataSource;
@property (nonatomic, weak) id <LMDropDownMenuDelegate> delegate;

@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *separatorColor;

- (instancetype)initWithOrigin:(CGPoint)origin andHeight:(CGFloat)height;

@end
