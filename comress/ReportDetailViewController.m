//
//  ReportDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportDetailViewController.h"
#import "ReportFiltersViewController.h"

@interface ReportDetailViewController ()

@end

@implementation ReportDetailViewController

@synthesize reportType,POisLoggedIn,PMisLoggedIn;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    self.selectedDivisionId = [NSNumber numberWithInt:0];
    self.selectedZoneId = [NSNumber numberWithInt:0];
    
    if(POisLoggedIn)
        self.filterLabel.hidden = YES;
    else if (PMisLoggedIn)
    {
        self.filterLabel.hidden = NO;
        [self getDivision]; //purpose is only to get the default division of this PM
    }
    
    
    //add tap gesture to filter to toggle filter view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFilter)];
    tap.numberOfTapsRequired = 1;
    self.filterLabel.userInteractionEnabled = YES;
    [self.filterLabel addGestureRecognizer:tap];
    
    NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
    self.filterLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Filters: None"
                                                             attributes:underlineAttribute];
    
    //average sentiment division filter is no need
    if(PMisLoggedIn && [reportType isEqualToString:@"Average Sentiment"])
        self.filterLabel.hidden = YES;
    
    [self setDefaultDateRange];
    
    self.title = reportType;
    
    //filter listeners

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterReports:) name:@"filterReports" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeReportsFilter) name:@"closeReportsFilter" object:nil];
}

- (void)getDivision
{
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_get_divisions] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *top = (NSDictionary *)responseObject;
        
        NSArray *DivistionList = [top objectForKey:@"DivistionList"];
        
        for (int i = 0; i < DivistionList.count; i++) {
            NSDictionary *dict = [DivistionList objectAtIndex:i];
            
            NSNumber *IsOwnDiv = [NSNumber numberWithBool:[[dict valueForKey:@"IsOwnDiv"] boolValue]];
            
            if([IsOwnDiv intValue] == 1)
            {
                self.defaultDivisionId = [NSNumber numberWithInt:[[dict valueForKey:@"DivId"] intValue]];
                self.filterLabel.text = [NSString stringWithFormat:@"Filters: %@, All",[dict valueForKey:@"DivName"]];
                break;
            }
        }
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [self getDivision];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGRect f = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    f.size.height = self.theWebView.frame.size.height - 5;
    f.origin.y = self.theWebView.frame.origin.y;
    
    webViewinitialFrame = f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self loadWebView];
}

- (void)viewDidLayoutSubviews {

    if([reportType isEqualToString:@"Average Sentiment"])
    {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if(orientation == 4 || orientation == 3)
        {
            self.navigationController.navigationBar.hidden = YES;
            self.tabBarController.tabBar.hidden = YES;
            
            self.theWebView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            
        }
        
        else
        {
            self.navigationController.navigationBar.hidden = NO;
            self.tabBarController.tabBar.hidden = NO;
            
            self.theWebView.frame = webViewinitialFrame;
        }
    }
}

- (void)filterReports:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    NSString *filter = @"Filters: None";
    
    if ([[dict objectForKey:@"division"] valueForKey:@"DivName"] != nil) {
        NSString *zoneStr;
        
        if([[dict objectForKey:@"zone"] valueForKey:@"ZoneName"] != [NSNull null])
            zoneStr = [[dict objectForKey:@"zone"] valueForKey:@"ZoneName"];
        
        if(zoneStr.length == 0)
            zoneStr = @"All";
        
        filter = [NSString stringWithFormat:@"Filters: %@, %@",[[dict objectForKey:@"division"] valueForKey:@"DivName"],zoneStr];
        
        self.selectedDivisionId = [NSNumber numberWithInt:[[[dict objectForKey:@"division"] valueForKey:@"DivId"] intValue]];
        self.selectedZoneId = [NSNumber numberWithInt:[[[dict objectForKey:@"zone"] valueForKey:@"ZoneId"] intValue]];
    }
    
    self.filterLabel.text = filter;
    
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        [self requestReportData];
    }];
}

- (void)closeReportsFilter
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:nil];
}

- (void)toggleFilter
{
    ReportFiltersViewController *reportsFilterVc = [self.storyboard instantiateViewControllerWithIdentifier:@"ReportFiltersViewController"];
    if(PMisLoggedIn && [reportType isEqualToString:@"Average Sentiment"])
        reportsFilterVc.hideZoneFilter = YES;
    else
        reportsFilterVc.hideZoneFilter = NO;
    
    reportsFilterVc.defaultDivision = self.defaultDivisionId;
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:reportsFilterVc];
    
    formSheet.presentedFormSheetSize = CGSizeMake(300, 400);
    formSheet.shadowRadius = 2.0;
    formSheet.shadowOpacity = 0.3;
    formSheet.shouldDismissOnBackgroundViewTap = YES;
    formSheet.shouldCenterVertically = YES;
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    // If you want to animate status bar use this code
    formSheet.didTapOnBackgroundViewCompletionHandler = ^(CGPoint location) {
        
    };
    
    formSheet.willPresentCompletionHandler = ^(UIViewController *presentedFSViewController) {
        DDLogVerbose(@"will present");
    };
    formSheet.transitionStyle = MZFormSheetTransitionStyleCustom;
    
    [MZFormSheetController sharedBackgroundWindow].formSheetBackgroundWindowDelegate = self;
    
    [self mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        DDLogVerbose(@"did present");
    }];
    
    formSheet.willDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        DDLogVerbose(@"will dismiss");
    };
}

- (void)loadWebView
{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlFile = nil;
    
    if(POisLoggedIn)
    {
        htmlFile = [[NSBundle mainBundle] pathForResource:@"TSAFBPO" ofType:@"html"];
        
        if([reportType isEqualToString:@"Feedback Issues"])
        {
            htmlFile = [[NSBundle mainBundle] pathForResource:@"TIWSBPO" ofType:@"html"];
        }
        else if ([reportType isEqualToString:@"Average Sentiment"])
            htmlFile = [[NSBundle mainBundle] pathForResource:@"ASBPO" ofType:@"html"];
        
    }
    else if (PMisLoggedIn)
    {
        htmlFile = [[NSBundle mainBundle] pathForResource:@"TSAFBPM" ofType:@"html"];
        
        if([reportType isEqualToString:@"Feedback Issues"])
            htmlFile = [[NSBundle mainBundle] pathForResource:@"TIWSBPM" ofType:@"html"];
        else if([reportType isEqualToString:@"Average Sentiment"])
            htmlFile = [[NSBundle mainBundle] pathForResource:@"ASBPM" ofType:@"html"];
    }
    
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.theWebView loadHTMLString:htmlString baseURL:baseURL];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    if(textField == self.fromDateTextFied)
    {
        self.actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeDate selectedDate:self.selectedFromDate target:self action:@selector(dateWasSelected:element:) origin:textField];
    }
    else
    {
        self.actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeDate selectedDate:self.selectedToDate target:self action:@selector(dateWasSelected:element:) origin:textField];
    }
    
    [self.actionSheetPicker addCustomButtonWithTitle:@"Today" value:[NSDate date]];
    [self.actionSheetPicker addCustomButtonWithTitle:@"Last Month" value:[[NSDate date] TC_dateByAddingCalendarUnits:NSCalendarUnitMonth amount:-1]];
    self.actionSheetPicker.hideCancel = YES;
    [self.actionSheetPicker showActionSheetPicker];
        
}
#pragma - mark date selection delegate
- (void)setDefaultDateRange
{
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:[NSDate date]];
    NSDate *startDate = [[NSCalendar currentCalendar]
                         dateFromComponents:components];
    
    self.selectedFromDate = [startDate dateByAddingTimeInterval:-2592000]; //last month
    self.selectedToDate = startDate;
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    NSString *datestringToday = [format stringFromDate:self.selectedToDate];
    self.toDateTextField.text = datestringToday;
    
    NSString *lastMonthString = [format stringFromDate:self.selectedFromDate];
    self.fromDateTextFied.text = lastMonthString;
}

- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:selectedDate];
    NSDate *cleanDateWithoutTime = [[NSCalendar currentCalendar]
                         dateFromComponents:components];
    
    selectedDate = cleanDateWithoutTime;
    
    UITextField *textField = (UITextField *)element;
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    if(textField == self.fromDateTextFied)
    {
        self.selectedFromDate = selectedDate;
        
        NSString *datestring = [format stringFromDate:self.selectedFromDate];
        textField.text = datestring;
    }
    else
    {
        self.selectedToDate = selectedDate;
        
        NSString *datestring = [format stringFromDate:self.selectedToDate];
        textField.text = datestring;
    }
    
    [self requestReportData];
}
- (IBAction)dateFilterToggle:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIButton *btn = (UIButton *)sender;
    NSInteger tag = btn.tag;
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:now];
    NSDate *cleanDateWithoutTime = [[NSCalendar currentCalendar]
                                    dateFromComponents:components];
    
    switch (tag) {
        case 2://this week
        {
            self.selectedFromDate = [cleanDateWithoutTime dateByAddingTimeInterval:-7*24*60*60];
            self.selectedToDate = cleanDateWithoutTime;
            
            break;
        }
            
        case 3://this month
        {
            self.selectedFromDate = [cleanDateWithoutTime dateByAddingTimeInterval:-2592000];
            self.selectedToDate = cleanDateWithoutTime;
            
            break;
        }
            
            
            
        default://today
            self.selectedFromDate = cleanDateWithoutTime;
            self.selectedToDate = cleanDateWithoutTime;
            break;
    }
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    NSString *datestringFrom = [format stringFromDate:self.selectedFromDate];
    self.fromDateTextFied.text = datestringFrom;
    
    NSString *datestringTo = [format stringFromDate:self.selectedToDate];
    self.toDateTextField.text = datestringTo;
    
    [self requestReportData];
}

#pragma - mark division and zone filter
- (IBAction)filterDivision:(id)sender
{

}

- (IBAction)filterZone:(id)sender
{
    
}

#pragma - mark uiwebview delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self requestReportData];
    
    //auto fit uiwebview
    UIScrollView *sv = [[self.theWebView subviews] objectAtIndex:0];
    [sv zoomToRect:CGRectMake(0, 0, sv.contentSize.width, sv.contentSize.height) animated:YES];
}

#pragma  - mark data request
- (void)requestReportData
{
    NSString *wcfDateFrom = [self serializedStringDateJson:self.selectedFromDate];
    NSString *wcfDateTo   = [self serializedStringDateJson:self.selectedToDate];
    
    
    NSString *urlString = nil;
    NSString *params = nil;
    
    if(POisLoggedIn)
    {
        urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_po];
        
        if([reportType isEqualToString:@"Survey"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_survey_po];
        
        else if ([reportType isEqualToString:@"Average Sentiment"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_average_sentiment];
        
        NSString *borderUrl = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_average_sentiment_border];
        
        params = [myDatabase toJsonString:@{@"startDate":wcfDateFrom,@"endDate":wcfDateTo,@"url":urlString,@"session":[myDatabase.userDictionary valueForKey:@"guid"],@"layer":[NSNumber numberWithInt:1],@"borderUrl":borderUrl}];
    }
    else if (PMisLoggedIn)
    {
        urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_po];
        
        if([reportType isEqualToString:@"Survey"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_survey_pm];
        else if ([reportType isEqualToString:@"Feedback Issues"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_pm];
        else
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_average_sentiment];
        
        NSNumber *theDivisionId = self.selectedDivisionId;
        
        NSString *borderUrl = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_average_sentiment_border];
        
        if([self.defaultDivisionId intValue] > 0 && [self.selectedDivisionId intValue] == 0)
            theDivisionId = self.defaultDivisionId;
        
        params = [myDatabase toJsonString:@{@"startDate":wcfDateFrom,@"endDate":wcfDateTo,@"url":urlString,@"session":[myDatabase.userDictionary valueForKey:@"guid"],@"divId":theDivisionId,@"zoneId":self.selectedZoneId,@"layer":[NSNumber numberWithInt:1],@"borderUrl":borderUrl}];
    }

    [self executeJavascript:@"requestData" withJsonObject:params];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

-(void)executeJavascript:(NSString *)methodName withJsonObject:(NSString *)object
{
    NSData *jsonData = [object dataUsingEncoding:NSUTF8StringEncoding];
    
    // Base64 encode the string to avoid problems
    NSString *encodedString = [jsonData base64EncodedStringWithOptions:0];
    
    // Evaluate your JavaScript function with the encoded string as input
    NSString *jsCall = [NSString stringWithFormat:@"%@(\"%@\")",methodName, encodedString];
    [self.theWebView stringByEvaluatingJavaScriptFromString:jsCall];
}

#pragma - mark helper
- (NSString *)serializedStringDateJson: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}

@end
