//
//  GenericWebviewViewController.m
//  comress
//
//  Created by Diffy Romano on 28/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "GenericWebviewViewController.h"

@interface GenericWebviewViewController ()

@end

@implementation GenericWebviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    // Build the url and loadRequest
    
    NSRange range = [[myDatabase.userDictionary valueForKey:@"group_name"] rangeOfString:@"CT"];

    if(range.location == NSNotFound)
        [self.theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:user_manual_po]]];
    else
        [self.theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:user_manual_ct]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
