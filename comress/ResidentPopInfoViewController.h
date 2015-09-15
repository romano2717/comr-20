//
//  ResidentPopInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 7/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPGTextField.h"
#import "Database.h"
#import "Survey.h"
#import "Blocks.h"
#import "ActionSheetStringPicker.h"

@interface ResidentPopInfoViewController : UIViewController<MPGTextFieldDelegate,UITextFieldDelegate>
{
    Database *myDatabase;
    Survey *mySurvey;
    Blocks *blocks;
}
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) NSNumber *surveyId;
@property (nonatomic, strong) NSNumber *clientSurveyId;

@property (nonatomic, weak) IBOutlet MPGTextField *surveyAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *areaTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *residentNameTxtFld;
@property (nonatomic, weak) IBOutlet UIButton *ageBtn;
@property (nonatomic, weak) IBOutlet UIButton *genderBtn;
@property (nonatomic, weak) IBOutlet UIButton *raceBtn;
@property (nonatomic, weak) IBOutlet UITextField *residentAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *unitNoTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *contactTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *otherContactTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *emailTxFld;

@property (nonatomic, strong) NSString *selectedGender;
@property (nonatomic, strong) NSString *selectedRace;
@property (nonatomic, strong) NSString *selectedAgeRange;
@property (nonatomic, strong) NSString *gender;

@property (nonatomic, strong) NSArray *ageRangeArray;
@property (nonatomic, strong) NSArray *raceArray;

@property (nonatomic) long long client_resident_address_id;
@property (nonatomic) long long client_survey_address_id;

@property (nonatomic, strong) NSString *surveyAddressPostalCode;
@property (nonatomic, strong) NSString *residentAddressPostalCode;

@property (nonatomic, strong) NSMutableArray *addressArray;
@property (nonatomic, strong) NSNumber *blockId;
@property (nonatomic, strong) NSNumber *residentBlockId;
@property (nonatomic) BOOL residentAddressIsNew;

@end
