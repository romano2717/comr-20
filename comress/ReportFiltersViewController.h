//
//  ReportFiltersViewController.h
//  comress
//
//  Created by Diffy Romano on 15/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionSheetStringPicker.h"
#import "Database.h"
#import "MBProgressHUD.h"

@interface ReportFiltersViewController : UIViewController<UITextFieldDelegate>
{
    Database *myDatabase;
}

@property (nonatomic,weak) IBOutlet UITextField *divisionTextField;
@property (nonatomic,weak) IBOutlet UITextField *zoneTextField;
@property (nonatomic,weak) IBOutlet UILabel *zoneLabel;
@property (nonatomic,weak) IBOutlet UITextField *precinctTextField;

@property (nonatomic, strong) NSMutableArray *divisionArray;
@property (nonatomic, strong) NSMutableArray *zoneArray;

@property (nonatomic, strong) NSMutableArray *divisionArrayObj;
@property (nonatomic, strong) NSMutableArray *zoneArrayObj;

@property (nonatomic, strong) NSDictionary *selectedDivisionDict;
@property (nonatomic, strong) NSDictionary *selectedZoneDict;

@property (nonatomic) BOOL hideZoneFilter; //when PM view the average sentiment, no nee for zone filtering

@property (nonatomic, strong) NSNumber *defaultDivision;
@end
