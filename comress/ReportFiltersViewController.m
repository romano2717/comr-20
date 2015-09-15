//
//  ReportFiltersViewController.m
//  comress
//
//  Created by Diffy Romano on 15/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportFiltersViewController.h"

@interface ReportFiltersViewController ()

@end

@implementation ReportFiltersViewController

@synthesize hideZoneFilter,defaultDivision;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    self.divisionArray = [[NSMutableArray alloc] init];
    self.zoneArray = [[NSMutableArray alloc] init];
    
    self.divisionArrayObj = [[NSMutableArray alloc] init];
    self.zoneArrayObj = [[NSMutableArray alloc] init];

    if(hideZoneFilter)
    {
        self.zoneTextField.hidden = YES;
        self.zoneLabel.hidden = YES;
    }
    
    [self getDivisions];
}

- (void)getDivisions
{
    //get division
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self.divisionArray removeAllObjects];
    [self.divisionArrayObj removeAllObjects];
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_get_divisions] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *top = (NSDictionary *)responseObject;
        
        NSArray *DivistionList = [top objectForKey:@"DivistionList"];
        
        for (int i = 0; i < DivistionList.count; i++) {
            NSDictionary *dict = [DivistionList objectAtIndex:i];
            NSString *divisionName = [dict valueForKey:@"DivName"];
            
            [self.divisionArray addObject:divisionName];
            [self.divisionArrayObj addObject:dict];
            
            if([defaultDivision intValue] == [[dict valueForKey:@"DivId"] intValue])
            {
                self.divisionTextField.text = divisionName;
                self.selectedDivisionDict = dict;
                
                //default zone : All
                [self.zoneArray addObject:@"All"];
                [self.zoneArrayObj addObject:@{@"DivId":[NSNumber numberWithInt:0],@"ZoneId":[NSNumber numberWithInt:0],@"ZoneName":@""}];
                self.zoneTextField.text = @"All";
                self.selectedZoneDict = [self.zoneArrayObj firstObject];
            }
        }
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [self getDivisions];
    }];
}

- (void)getZoneForDivisionId:(NSNumber *)divisionId
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self.zoneArray removeAllObjects];
    [self.zoneArrayObj removeAllObjects];
    
    //default zone : All
    [self.zoneArray addObject:@"All"];
    [self.zoneArrayObj addObject:@{@"DivId":[NSNumber numberWithInt:0],@"ZoneId":[NSNumber numberWithInt:0],@"ZoneName":@""}];
    self.zoneTextField.text = @"All";
    self.selectedZoneDict = [self.zoneArrayObj firstObject];
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_get_zones] parameters:@{@"divId":divisionId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *top = (NSDictionary *)responseObject;
        
        NSArray *DivistionList = [top objectForKey:@"ZoneList"];
        
        for (int i = 0; i < DivistionList.count; i++) {
            NSDictionary *dict = [DivistionList objectAtIndex:i];
            NSString *divisionName = [dict valueForKey:@"ZoneName"];
            
            [self.zoneArray addObject:divisionName];
            [self.zoneArrayObj addObject:dict];
        }
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [self getZoneForDivisionId:divisionId];
    }];
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
    
    if(textField == self.divisionTextField)
        [self selectDivision:textField];
    else if (textField == self.zoneTextField)
        [self selectZone:textField];
}

- (IBAction)cancel:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeReportsFilter" object:nil];
}

- (IBAction)filter:(id)sender
{
    NSDictionary *dict = @{@"division":self.selectedDivisionDict ? self.selectedDivisionDict : @"",@"zone":self.selectedZoneDict ? self.selectedZoneDict : @""};
    DDLogVerbose(@"filter %@",dict);
    
    if(self.selectedDivisionDict == nil && self.selectedZoneDict == nil)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeReportsFilter" object:nil];

    else
        [[NSNotificationCenter defaultCenter] postNotificationName:@"filterReports" object:nil userInfo:dict];
}

- (void)selectDivision:(id)sender
{
    [ActionSheetStringPicker showPickerWithTitle:@"Select Division" rows:self.divisionArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        self.selectedDivisionDict = [self.divisionArrayObj objectAtIndex:selectedIndex];
        
        NSNumber *selectedDivisionId = [NSNumber numberWithInt:[[[self.divisionArrayObj objectAtIndex:selectedIndex] valueForKey:@"DivId"] intValue]];
        
        [self getZoneForDivisionId:selectedDivisionId];
        
        UITextField *txtFld = (UITextField *)sender;
        txtFld.text = [self.divisionArray objectAtIndex:selectedIndex];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}

- (void)selectZone:(id)sender
{
    if(self.divisionTextField.text.length == 0)
        return;
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select Zone" rows:self.zoneArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        self.selectedZoneDict = [self.zoneArrayObj objectAtIndex:selectedIndex];
        
        UITextField *txtFld = (UITextField *)sender;
        txtFld.text = [self.zoneArray objectAtIndex:selectedIndex];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}
@end
