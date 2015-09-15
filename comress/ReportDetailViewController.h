//
//  ReportDetailViewController.h
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionSheetDatePicker.h"
#import "NSDate+TCUtils.h"
#import "AppWideImports.h"
#import "Database.h"
#import "MZFormSheetController.h"
#import "MZCustomTransition.h"
#import "MZFormSheetSegue.h"
#import "MBProgressHUD.h"

@interface ReportDetailViewController : UIViewController<UIWebViewDelegate, UITextFieldDelegate,MZFormSheetBackgroundWindowDelegate>
{
    Database *myDatabase;
    
    CGRect webViewinitialFrame;
}

@property (nonatomic, weak) IBOutlet UITextField *fromDateTextFied;
@property (nonatomic, weak) IBOutlet UITextField *toDateTextField;
@property (nonatomic, weak) IBOutlet UIWebView *theWebView;
@property (nonatomic, weak) IBOutlet UILabel *filterLabel;

@property (nonatomic, strong) AbstractActionSheetPicker *actionSheetPicker;
@property (nonatomic, strong) NSDate *selectedFromDate;
@property (nonatomic, strong) NSDate *selectedToDate;

@property (nonatomic, strong) NSNumber *selectedDivisionId;
@property (nonatomic, strong) NSNumber *selectedZoneId;

@property (nonatomic, strong) NSString *reportType;
@property (nonatomic) BOOL PMisLoggedIn;
@property (nonatomic) BOOL POisLoggedIn;

@property (nonatomic, strong) NSNumber *defaultDivisionId;



@end
