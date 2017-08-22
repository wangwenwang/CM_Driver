//
//  LMDropMenu.m
//  downDropMenu
//
//  Created by 凯东源 on 17/6/4.
//  Copyright © 2017年 xx. All rights reserved.
//

#import "LMDropMenu.h"
#import "LMDropDownMenuTableViewCell.h"
#import <Masonry.h>
#import <Foundation/Foundation.h>

#define BackColor [UIColor colorWithRed:244.0f/255.0f green:244.0f/255.0f blue:244.0f/255.0f alpha:1.0]

// 选中颜色加深
#define SelectColor [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0]

#define kCellName @"LMDropDownMenuTableViewCell"

#define kCellHeight 44.1

#define kCompleteBtn_top 10

#define kCompleteBtn_bottom 10

#define kCompleteBtn_right 10

#define kCompleteBtn_width 67

#define kCompleteBtn_height 30

#define kTableFooterViewHeight (kCompleteBtn_top + kCompleteBtn_height + kCompleteBtn_bottom)



@implementation LMIndexPath
- (instancetype)initWithColumn:(NSInteger)column andRow:(NSInteger)row {
    
    if (self = [super init]) {
        
        _column = column;
        _row = row;
    }
    return self;
}

+ (instancetype)indexPathWithCol:(NSInteger)col row:(NSInteger)row {
    
    LMIndexPath *indexPath = [[self alloc] initWithColumn:col andRow:row];
    return indexPath;
}
@end



@interface NSString (Size)

- (CGSize)textSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

@implementation NSString (Size)

- (CGSize)textSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize textSize;
    if (CGSizeEqualToSize(size, CGSizeZero))
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        
        textSize = [self sizeWithAttributes:attributes];
    }
    else
    {
        NSStringDrawingOptions option = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
        //NSStringDrawingTruncatesLastVisibleLine如果文本内容超出指定的矩形限制，文本将被截去并在最后一个字符后加上省略号。 如果指定了NSStringDrawingUsesLineFragmentOrigin选项，则该选项被忽略 NSStringDrawingUsesFontLeading计算行高时使用行间距。（字体大小+行间距=行高）
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        CGRect rect = [self boundingRectWithSize:size
                                         options:option
                                      attributes:attributes
                                         context:nil];
        
        textSize = rect.size;
    }
    return textSize;
}

@end



@interface LMDropMenu ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) NSUInteger currentSelectedMenudIndex;

@property (nonatomic, assign) BOOL show;

@property (nonatomic, assign) NSInteger numOfMenu;

@property (nonatomic, assign) CGPoint origin;

@property (nonatomic, strong) UIView *backGroundView;

@property (nonatomic, strong) UIView *bottomShadow;

@property (nonatomic, strong) NSMutableArray *currentSelectedMenudIndexs;

@property (nonatomic, strong) UIView *tableViewSuper;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *selectedList;

//layers array
@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, copy) NSArray *indicators;
@property (nonatomic, copy) NSArray *bgLayers;

// 底部视图
@property (strong, nonatomic) UIView *footerView;

@property (strong, nonatomic) UIButton *completeBtn;

@property (strong, nonatomic) UIButton *antiElectionBtn;

// tableViewSuper 高度
@property (nonatomic, strong) MASConstraint *tableViewSuperHeight;

@property (nonatomic, strong) MASConstraint *tableViewSuperTop;

@property (nonatomic, strong) MASConstraint *tableViewSuperRight_Left;

@end

@implementation LMDropMenu

#pragma mark - init method

- (instancetype)initWithOrigin:(CGPoint)origin andHeight:(CGFloat)height {
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self = [self initWithFrame:CGRectMake(origin.x, origin.y, screenSize.width, height)];
    
    if (self) {
        _origin = origin;
        _currentSelectedMenudIndexs = [[NSMutableArray alloc] init];
        _show = NO;
        
        // tableViewSuper init
        _tableViewSuper = [[UIView alloc] init];
        _tableViewSuper.clipsToBounds = YES;
        _tableViewSuper.backgroundColor = [UIColor colorWithRed:251 / 255.0 green:251 / 255.0 blue:251 / 255.0 alpha:1.0];
        
        // 反选按钮
        _antiElectionBtn = [[UIButton alloc] init];
        _antiElectionBtn.backgroundColor = [UIColor colorWithRed:0 / 255.0 green:202 / 255.0 blue:177 / 255.0 alpha:1.0];
        [_antiElectionBtn setTitle:@"反选" forState:UIControlStateNormal];
        _antiElectionBtn.layer.cornerRadius = 3.0f;
        [_antiElectionBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [_antiElectionBtn addTarget:self action:@selector(antiElectionOnclick) forControlEvents:UIControlEventTouchUpInside];
        [_tableViewSuper addSubview:_antiElectionBtn];
        
        [_antiElectionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.width.mas_equalTo(kCompleteBtn_width);
            make.height.mas_equalTo(kCompleteBtn_height);
            make.left.mas_equalTo(kCompleteBtn_right);
            make.bottom.mas_equalTo(- kCompleteBtn_bottom);
        }];
        
        // 完成按钮
        _completeBtn = [[UIButton alloc] init];
        _completeBtn.backgroundColor = [UIColor colorWithRed:0 / 255.0 green:202 / 255.0 blue:177 / 255.0 alpha:1.0];
        [_completeBtn setTitle:@"完成" forState:UIControlStateNormal];
        _completeBtn.layer.cornerRadius = 3.0f;
        [_completeBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [_completeBtn addTarget:self action:@selector(completeOnclick) forControlEvents:UIControlEventTouchUpInside];
        [_tableViewSuper addSubview:_completeBtn];
        
        [_completeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.width.mas_equalTo(kCompleteBtn_width);
            make.height.mas_equalTo(kCompleteBtn_height);
            make.right.mas_equalTo(- kCompleteBtn_right);
            make.bottom.mas_equalTo(- kCompleteBtn_bottom);
        }];
        
        // tableView init
        _tableView = [[UITableView alloc] init];
        _tableView.separatorStyle = NO;
        _tableView.rowHeight = kCellHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        self.autoresizesSubviews = NO;
        _tableView.autoresizesSubviews = NO;
        
        [_tableViewSuper addSubview:_tableView];
        
//        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.mas_equalTo(0);
//            make.left.mas_equalTo(0);
//            make.right.mas_equalTo(0);
//            make.bottom.equalTo(_completeBtn.mas_top).offset(- kCompleteBtn_top);
//        }];
        
        
        [self registerCell];
        
        // self tapped
//        self.backgroundColor = [UIColor greenColor];
        UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuTapped:)];
        [self addGestureRecognizer:tapGesture];
        
        // background init and tapped
        _backGroundView = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y, screenSize.width, screenSize.height)];
        _backGroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        _backGroundView.opaque = NO;
        UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [_backGroundView addGestureRecognizer:gesture];
        
        //add bottom shadow
        _bottomShadow = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 0.5, screenSize.width, 0.5)];
        [self addSubview:_bottomShadow];
        
        _selectedList = [[NSMutableArray alloc] init];
        NSLog(@"");
    }
    return self;
}


#pragma mark - 事件

- (void)completeOnclick {
    
    [self hiddenMenu];
    
    if([_delegate respondsToSelector:@selector(filterComplete)]) {
        
        [_delegate filterComplete];
    }
}


- (void)antiElectionOnclick {
    
    if([_delegate respondsToSelector:@selector(antiElectionOnclick)]) {
        
        [_delegate antiElectionOnclick];
    }
    
    [_tableView reloadData];
}


- (void)hiddenMenu {
    
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView leftTableView:_tableView rightTableView:nil title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        _show = NO;
    }];
    
    [(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:BackColor.CGColor];
}


- (void)filterCancel{
    
    if([_delegate respondsToSelector:@selector(filterCancel)]) {
        
        [_delegate filterCancel];
    }
}


#pragma mark - init support

- (void)createSelectedArray {
    
    NSUInteger count =  [self.dataSource menu:self numberOfRowsInColumn:_currentSelectedMenudIndex];
    
    for ( int i = 0; i < count; i++) {
        
//        _selectedList
    }
}


- (CALayer *)createBgLayerWithColor:(UIColor *)color andPosition:(CGPoint)position {
    CALayer *layer = [CALayer layer];
    
    layer.position = position;
    layer.bounds = CGRectMake(0, 0, self.frame.size.width/self.numOfMenu, self.frame.size.height-1);
    layer.backgroundColor = color.CGColor;
    
    return layer;
}


- (CATextLayer *)createTextLayerWithNSString:(NSString *)string withColor:(UIColor *)color andPosition:(CGPoint)point {
    
    CGSize size = [self calculateTitleSizeWithString:string];
    
    CATextLayer *layer = [CATextLayer new];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    layer.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    layer.string = string;
    layer.fontSize = 14.0;
    layer.alignmentMode = kCAAlignmentCenter;
    layer.foregroundColor = color.CGColor;
    
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    layer.position = point;
    
    return layer;
}


- (CAShapeLayer *)createIndicatorWithColor:(UIColor *)color andPosition:(CGPoint)point {
    CAShapeLayer *layer = [CAShapeLayer new];
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(8, 0)];
    [path addLineToPoint:CGPointMake(4, 5)];
    [path closePath];
    
    layer.path = path.CGPath;
    layer.lineWidth = 1.0;
    layer.fillColor = color.CGColor;
    
    CGPathRef bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, layer.miterLimit);
    layer.bounds = CGPathGetBoundingBox(bound);
    
    CGPathRelease(bound);
    
    layer.position = point;
    
    return layer;
}


- (CAShapeLayer *)createSeparatorLineWithColor:(UIColor *)color andPosition:(CGPoint)point {
    CAShapeLayer *layer = [CAShapeLayer new];
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:CGPointMake(160,0)];
    [path addLineToPoint:CGPointMake(160, self.frame.size.height)];
    
    layer.path = path.CGPath;
    layer.lineWidth = 1.0;
    layer.strokeColor = color.CGColor;
    
    CGPathRef bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, layer.miterLimit);
    layer.bounds = CGPathGetBoundingBox(bound);
    
    CGPathRelease(bound);
    
    layer.position = point;
    
    return layer;
}


#pragma mark - SET方法

- (void)setDataSource:(id<LMDropDownMenuDataSource>)dataSource {
    
    _dataSource = dataSource;
    
    //configure view
    if ([_dataSource respondsToSelector:@selector(numberOfColumnsInMenu:)]) {
        _numOfMenu = [_dataSource numberOfColumnsInMenu:self];
    } else {
        _numOfMenu = 1;
    }
    
    CGFloat textLayerInterval = self.frame.size.width / ( _numOfMenu * 2);
    
    CGFloat separatorLineInterval = self.frame.size.width / _numOfMenu;
    
    CGFloat bgLayerInterval = self.frame.size.width / _numOfMenu;
    
    NSMutableArray *tempTitles = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempIndicators = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempBgLayers = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    
    for (int i = 0; i < _numOfMenu; i++) {
        //bgLayer
        CGPoint bgLayerPosition = CGPointMake((i+0.5)*bgLayerInterval, self.frame.size.height/2);
        CALayer *bgLayer = [self createBgLayerWithColor:BackColor andPosition:bgLayerPosition];
        [self.layer addSublayer:bgLayer];
        [tempBgLayers addObject:bgLayer];
        //title
        CGPoint titlePosition = CGPointMake( (i * 2 + 1) * textLayerInterval , self.frame.size.height / 2);
        NSString *titleString = [_dataSource menu:self titleForColumn:i];
        CATextLayer *title = [self createTextLayerWithNSString:titleString withColor:self.textColor andPosition:titlePosition];
        [self.layer addSublayer:title];
        [tempTitles addObject:title];
        //indicator
        CAShapeLayer *indicator = [self createIndicatorWithColor:self.indicatorColor andPosition:CGPointMake(titlePosition.x + title.bounds.size.width / 2 + 8, self.frame.size.height / 2)];
        [self.layer addSublayer:indicator];
        [tempIndicators addObject:indicator];
        
        //separator
        if (i != _numOfMenu - 1) {
            CGPoint separatorPosition = CGPointMake((i + 1) * separatorLineInterval, self.frame.size.height/2);
            CAShapeLayer *separator = [self createSeparatorLineWithColor:self.separatorColor andPosition:separatorPosition];
            [self.layer addSublayer:separator];
        }
    }
    
    _bottomShadow.backgroundColor = self.separatorColor;
    
    _titles = [tempTitles copy];
    _indicators = [tempIndicators copy];
    _bgLayers = [tempBgLayers copy];
}


#pragma mark - 手势

- (void)menuTapped:(UITapGestureRecognizer *)paramSender {
    
    CGPoint touchPoint = [paramSender locationInView:self];
    
    // calculate index
    NSInteger tapIndex = touchPoint.x / (self.frame.size.width / _numOfMenu);
    
    if([_delegate respondsToSelector:@selector(menuTapped:)]) {
        
        [_delegate menuTapped:tapIndex];
    }
    
    for (int i = 0; i < _numOfMenu; i++) {
        if (i != tapIndex) {
            [self animateIndicator:_indicators[i] Forward:NO complete:^{
                [self animateTitle:_titles[i] show:NO complete:^{
                    
                }];
            }];
            [(CALayer *)self.bgLayers[i] setBackgroundColor:BackColor.CGColor];
        }
    }
    
    if (tapIndex == _currentSelectedMenudIndex && _show) {
        
        [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView leftTableView:_tableView rightTableView:nil title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
            _currentSelectedMenudIndex = tapIndex;
            _show = NO;
        }];
        
        [(CALayer *)self.bgLayers[tapIndex] setBackgroundColor:BackColor.CGColor];
    } else {
        
        _currentSelectedMenudIndex = tapIndex;
        
        [_tableView reloadData];
        
        [self animateIdicator:_indicators[tapIndex] background:_backGroundView leftTableView:_tableView rightTableView:nil title:_titles[tapIndex] forward:YES complecte:^{
            _show = YES;
        }];
        
        // 防止 iOS8 动画异常
//        [_tableView reloadData];
        
        [(CALayer *)self.bgLayers[tapIndex] setBackgroundColor:SelectColor.CGColor];
        
    }
    
    [self filterCancel];
}


- (void)backgroundTapped:(UITapGestureRecognizer *)paramSender {
    
    [self hiddenMenu];
    
    [self filterCancel];
}


#pragma mark - animation method

- (void)animateIndicator:(CAShapeLayer *)indicator Forward:(BOOL)forward complete:(void(^)())complete {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.25];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :0.2 :1.0]];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    anim.values = forward ? @[ @0, @(M_PI) ] : @[ @(M_PI), @0 ];
    
    if (!anim.removedOnCompletion) {
        [indicator addAnimation:anim forKey:anim.keyPath];
    } else {
        [indicator addAnimation:anim forKey:anim.keyPath];
        [indicator setValue:anim.values.lastObject forKeyPath:anim.keyPath];
    }
    
    [CATransaction commit];
    
    complete();
}


- (void)animateTitle:(CATextLayer *)title show:(BOOL)show complete:(void(^)())complete {
    CGSize size = [self calculateTitleSizeWithString:title.string];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    title.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    complete();
}


- (void)animateIdicator:(CAShapeLayer *)indicator background:(UIView *)background leftTableView:(UITableView *)leftTableView rightTableView:(UITableView *)rightTableView title:(CATextLayer *)title forward:(BOOL)forward complecte:(void(^)())complete{
    
    [self animateIndicator:indicator Forward:forward complete:^{
        [self animateTitle:title show:forward complete:^{
            [self animateBackGroundView:background show:forward complete:^{
                [self animateLeftTableView:leftTableView rightTableView:rightTableView show:forward complete:^{
                }];
            }];
        }];
    }];
    
    complete();
}


/**
 *动画显示下拉菜单
 */
- (void)animateLeftTableView:(UITableView *)leftTableView rightTableView:(UITableView *)rightTableView show:(BOOL)show complete:(void(^)())complete {
    
    if (show) {
        
        CGFloat tableViewHeight = 0;
        
        if (_tableViewSuper) {
            
            [_tableViewSuper setFrame:CGRectMake(0, kLMMenuHeight_Supply, ScreenWidth, 0)];
            
            [self.superview addSubview:_tableViewSuper];
            
//            __weak __typeof(self) weakSelf = self;
//            [_tableViewSuper mas_makeConstraints:^(MASConstraintMaker *make) {
//                
//                _tableViewSuperTop = make.top.mas_equalTo(CGRectGetHeight(self.frame));
//                _tableViewSuperRight_Left = make.left.right.equalTo(weakSelf.superview);
//                _tableViewSuperHeight = make.height.mas_equalTo(0);
//            }];
//            [_tableViewSuper layoutIfNeeded];
            
            // 菜单可用高度
            CGFloat heightALL = ScreenHeight - 64 - kLMMenuHeight_Supply - 49;
            
            // 菜单规定高度
            CGFloat heightPart = heightALL - kTableFooterViewHeight - 80;
            
            // Cell个数
            NSUInteger cellCount = [leftTableView numberOfRowsInSection:0];
            
            if((cellCount * kCellHeight) > heightPart) {
                
                for (int i = 0; i < cellCount; i++) {
                    
                    tableViewHeight += kCellHeight;
                    if(tableViewHeight > heightPart) {
                        
                        tableViewHeight = tableViewHeight - kCellHeight / 2 + kTableFooterViewHeight;
                        break;
                    }
                }
            } else {
                
                tableViewHeight = cellCount * kCellHeight + kTableFooterViewHeight;
            }
            
            NSLog(@"");
        }
//        
//        [_tableViewSuperHeight uninstall];
//        [_tableViewSuperTop uninstall];
//        [_tableViewSuperRight_Left uninstall];
//        
//        __weak __typeof(self) weakSelf = self;
//        
//        NSLog(@"dddd%@", NSStringFromCGRect(_tableViewSuper.frame));
//        
//        [_tableViewSuper mas_updateConstraints:^(MASConstraintMaker *make) {
//            
//            _tableViewSuperTop = make.top.mas_equalTo(CGRectGetHeight(self.frame));
//            _tableViewSuperRight_Left = make.left.right.equalTo(weakSelf.superview);
//            make.height.mas_equalTo(tableViewHeight);
//        }];
//        
//        [UIView animateWithDuration:4.2 animations:^{
//        
//            [_tableViewSuper layoutIfNeeded];
//        }];
//        
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//           
//            sleep(5);
//            dispatch_async(dispatch_get_main_queue(), ^{
//               
//                NSLog(@"dddd%@", NSStringFromCGRect(_tableViewSuper.frame));
//            });
//        });
        
        [_tableView setFrame:CGRectMake(0, 0, ScreenWidth, tableViewHeight - kTableFooterViewHeight)];
        
        [UIView animateWithDuration:0.2 animations:^{
            
            [_tableViewSuper setFrame:CGRectMake(0, kLMMenuHeight_Supply, ScreenWidth, tableViewHeight)];
        }];
    } else {
        
        if (_tableViewSuper) {
            
//            if (_tableViewSuper) {
//                
//                [_tableViewSuper removeFromSuperview];
//            }
            
        [UIView animateWithDuration:0.2 animations:^{
            
            [_tableViewSuper setFrame:CGRectMake(0, kLMMenuHeight_Supply, ScreenWidth, 0)];
        } completion:^(BOOL finished) {
            
            if (_tableViewSuper) {
                
                [_tableViewSuper removeFromSuperview];
            }
        }];
        
        
        
//            [self.tableViewSuperHeight uninstall];
//
//            CGFloat fff = CGRectGetHeight(self.frame);
//            
//            [_tableViewSuper mas_updateConstraints:^(MASConstraintMaker *make) {
//                make.top.mas_equalTo(CGRectGetHeight(self.frame));
//                make.height.mas_equalTo(0);
//            }];
//            
//            [UIView animateWithDuration:4.2 animations:^{
//                
//                [_tableViewSuper layoutIfNeeded];
//            } completion:^(BOOL finished) {
//            
//                if (_tableViewSuper) {
//                    
//                    [_tableViewSuper removeFromSuperview];
//                }
//            }];
        }
    }
}


- (void)animateBackGroundView:(UIView *)view show:(BOOL)show complete:(void(^)())complete {
    if (show) {
        [self.superview addSubview:view];
        [view.superview addSubview:self];
        
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    }
    complete();
}


#pragma mark - 功能函数

- (CGSize)calculateTitleSizeWithString:(NSString *)string {
    
    CGFloat fontSize = 14.0;
    NSDictionary *dic = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    CGSize size = [string boundingRectWithSize:CGSizeMake(280, 0) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
    return size;
}


- (void)registerCell {
    
    [_tableView registerNib:[UINib nibWithNibName:kCellName bundle:nil] forCellReuseIdentifier:kCellName];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.dataSource menu:self numberOfRowsInColumn:_currentSelectedMenudIndex];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = kCellName;
    LMDropDownMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = BackColor;
    
    cell.titleLabel.textColor = self.textColor;
    cell.titleLabel.tag = 1;
    
    CGSize textSize;
    
    if ([self.dataSource respondsToSelector:@selector(menu:titleForRowAtIndexPath:)]) {
        
        DataItemModel *item = [self.dataSource menu:self titleForRowAtIndexPath:[LMIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
        cell.item = item;
        // 只取宽度
        textSize = [cell.titleLabel.text textSizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(MAXFLOAT, 14) lineBreakMode:NSLineBreakByWordWrapping];
    } else {
        
        NSAssert(0 == 1, @"required method of dataSource protocol should be implemented");
        return 0;
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    
    return cell;
}


#pragma mark - tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.delegate || [self.delegate respondsToSelector:@selector(menu:didSelectRowAtIndexPath:)]) {
        
//        [self confiMenuWithSelectRow:indexPath.row];
        
        [self.delegate menu:self didSelectRowAtIndexPath:[LMIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
        
        [_tableView reloadData];
    } else {
        
        //TODO: delegate is nil
    }
}


- (void)confiMenuWithSelectRow:(NSInteger)row {
    
    CATextLayer *title = (CATextLayer *)_titles[_currentSelectedMenudIndex];
    
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView leftTableView:_tableView rightTableView:nil title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        _show = NO;
    }];
    [(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:BackColor.CGColor];
    
    CAShapeLayer *indicator = (CAShapeLayer *)_indicators[_currentSelectedMenudIndex];
    indicator.position = CGPointMake(title.position.x + title.frame.size.width / 2 + 8, indicator.position.y);
}

@end
