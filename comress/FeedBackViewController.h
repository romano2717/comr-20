//
//  FeedBackViewController.h
//  comress
//
//  Created by Diffy Romano on 4/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "CreateIssueViewController.h"
#import "Survey.h"
#import "MPGTextField.h"
#import "Blocks.h"

@interface FeedBackViewController : UIViewController<UIScrollViewDelegate,UIAlertViewDelegate,MPGTextFieldDelegate,UIScrollViewDelegate,UITextFieldDelegate>
{
    Database *myDatabase;
    Blocks *blocks;    
}
@property (nonatomic)BOOL pushFromSurvey;
@property (nonatomic)BOOL pushFromSurveyDetail;

@property (nonatomic, strong) NSNumber *currentClientSurveyId;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet UITextView *feedBackTextView;

@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocSurveyAddBtn;
@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocResidentAddBtn;
@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocOthersAddBtn;
@property (nonatomic, weak) IBOutlet MPGTextField *othersAddTxtField;

@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, strong) NSString *selectedFeedBackLoc;
@property (nonatomic, strong) NSMutableArray *selectedFeeBackTypeArr;
@property (nonatomic, strong) NSMutableArray *selectedFeeBackTypeStringArr;

@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic, strong) NSString *residentPostalCode;

@property (nonatomic) BOOL pushFromSurveyAndModalFromFeedback;

@property (nonatomic, weak) IBOutlet UIButton *crmAssginBtn;

@property (nonatomic, strong) NSArray *crmAssignArray;
@property (nonatomic, strong) NSString *selectedCrmAssignmentForMaintenance;
@property (nonatomic, strong) NSString *selectedCrmAssignmentForOthers;

@property (nonatomic, strong) NSMutableArray *addressArray;
@property (nonatomic, strong) NSNumber *blockId;

@property (nonatomic) BOOL autoAssignToMeMaintenance;
@property (nonatomic) BOOL autoAssignToMeOthers;

@end
