//
//  ResidentInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ActionSheetStringPicker.h"
#import "Database.h"
#import "FeedBackViewController.h"
#import "SurveyDetailViewController.h"
#import "NearbyLocationsViewController.h"
#import "MBProgressHUD.h"
#import "MPGTextField.h"
#import "Blocks.h"

@class ResidentInfoViewController;

@interface ResidentInfoViewController : UIViewController<UIAlertViewDelegate,UIPopoverPresentationControllerDelegate,CLLocationManagerDelegate,MPGTextFieldDelegate,UITextFieldDelegate>
{
    Database *myDatabase;
    Blocks *blocks;
    CLLocationManager *locationManager;
    
    NearbyLocationsViewController *postInfoVc;
}
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet MPGTextField *surveyAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *areaTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *residentNameTxFld;

@property (nonatomic, weak) IBOutlet UITextField *residentAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *unitNoTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *contactNoTxFld;
@property (nonatomic, weak) IBOutlet UITextField *otherContactNoTxFld;
@property (nonatomic, weak) IBOutlet UITextField *emailTxFld;

@property (nonatomic, weak) IBOutlet UIButton *ageBtn;
@property (nonatomic, weak) IBOutlet UIButton *raceBtn;

@property (nonatomic, strong) NSNumber *surveyId;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLPlacemark *placemark;
@property (nonatomic,strong) NSString *postalCode;
@property (nonatomic,strong) NSString *residentPostalCode;

@property (nonatomic, strong) NSArray *ageRangeArray;
@property (nonatomic, strong) NSArray *raceArray;
@property (nonatomic, strong) NSString *gender;

@property (nonatomic) long long currentSurveyId;

@property (nonatomic, strong) NSNumber *averageRating;

@property (nonatomic, weak) IBOutlet UIView *disclaimerView;

@property (nonatomic) BOOL didTakeActionOnDataPrivacyTerms;

@property (nonatomic, strong) NSArray *foundPlacesArray;

@property (nonatomic) BOOL currentLocationFound;

@property (nonatomic) BOOL dismissPopupByReload; //don't validate postal code;

@property (nonatomic, strong) NSMutableArray *closeAreas;

@property (nonatomic, strong) NSMutableArray *addressArray;

@property (nonatomic, strong) NSNumber *blockId;
@property (nonatomic, strong) NSNumber *residentBlockId;

@property (nonatomic) BOOL didAddFeedBack;

//resume
@property (nonatomic)BOOL resumeSurvey;


- (void)selectedTableRowLocation:(NSNotification *)notif;

- (void)closePopUpWithLocationReload:(NSNotification *)notif;







@end
