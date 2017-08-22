//
//  AskedQusetionsViewController.m
//  CMClient
//
//  Created by 凯东源 on 17/5/18.
//  Copyright © 2017年 城马联盟. All rights reserved.
//

#import "AskedQusetionsViewController.h"

@interface AskedQusetionsViewController ()


@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation AskedQusetionsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"http://www.chengma.co/common.aspx"];
    
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
    
    LMLog(@"dd %s", __func__);
}

@end
