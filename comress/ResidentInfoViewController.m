//
//  ResidentInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentInfoViewController.h"
#import "Synchronize.h"

#import "MZFormSheetController.h"
#import "MZCustomTransition.h"
#import "MZFormSheetSegue.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface ResidentInfoViewController ()<MZFormSheetBackgroundWindowDelegate>
{
    
}

@property (nonatomic) BOOL okToSubmitForm;
@property (nonatomic, strong) NSString *formErrorMsg;
@end

@implementation ResidentInfoViewController

@synthesize surveyId,currentLocation,currentSurveyId,averageRating,placemark,didTakeActionOnDataPrivacyTerms,foundPlacesArray,blockId,residentBlockId,didAddFeedBack,okToSubmitForm,formErrorMsg;

//resume
@synthesize resumeSurvey;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    okToSubmitForm = YES;
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    [self generateData];
    
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePopUpWithLocationReload:) name:@"closePopUpWithLocationReload" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedTableRowLocation:) name:@"selectedTableRowLocation" object:nil];
    
    
    self.title = @"Data Protection";
    
    
    if(resumeSurvey)
        [self prepareToResumeThisSurvey];
}

- (void)prepareToResumeThisSurvey
{
    __block NSString *persist_surveyAddres;
    __block NSString *persist_specifyArea;
    __block NSString *persist_residentName;
    __block NSString *persist_age;
    __block NSString *persist_gender;
    __block NSString *persist_race;
    __block NSString *persist_residentAddress;
    __block NSString *persist_unitNo;
    __block NSString *persist_contact;
    __block NSString *persist_otherContact;
    __block NSString *persist_email;
    __block NSString *persist_surveyPostalCode;
    __block NSNumber *persist_surveyBlockId;
    __block NSString *persist_residentPostalCode;
    __block NSNumber *persist_residentBlockId;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",[NSNumber numberWithLongLong:currentSurveyId]];
        
        while ([rs next]) {
            persist_residentName = [rs stringForColumn:@"resident_name"];
            persist_age = [rs stringForColumn:@"resident_age_range"];
            persist_gender = [rs stringForColumn:@"resident_gender"];
            persist_race = [rs stringForColumn:@"resident_race"];
            persist_contact = [rs stringForColumn:@"resident_contact"];
            persist_email = [rs stringForColumn:@"resident_email"];
            persist_otherContact = [rs stringForColumn:@"other_contact"];
            
            NSNumber *clientSurveyAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
            NSNumber *clientResidentAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_resident_address_id"]];
            
            FMResultSet *rsGetSurveyAdds = [db executeQuery:@"select * from su_address where client_address_id = ?",clientSurveyAddressId];
            while ([rsGetSurveyAdds next]) {
                persist_surveyAddres = [rsGetSurveyAdds stringForColumn:@"address"];
                persist_specifyArea = [rsGetSurveyAdds stringForColumn:@"specify_area"];
                persist_surveyPostalCode = [rsGetSurveyAdds stringForColumn:@"postal_code"];
                persist_surveyBlockId = [NSNumber numberWithInt:[[rsGetSurveyAdds stringForColumn:@"block_id"] intValue]];
            }
            
            
            FMResultSet *rsGetResidAdds = [db executeQuery:@"select * from su_address where client_address_id = ?",clientResidentAddressId];
            while ([rsGetResidAdds next]) {
                persist_residentAddress = [rsGetResidAdds stringForColumn:@"address"];
                persist_unitNo = [rsGetResidAdds stringForColumn:@"unit_no"];
                persist_residentPostalCode = [rsGetResidAdds stringForColumn:@"postal_code"];
                persist_residentBlockId = [NSNumber numberWithInt:[[rsGetResidAdds stringForColumn:@"block_id"] intValue]];
            }
        }
    }];
    
    
    //fill-in the fields
    self.surveyAddressTxtFld.text = persist_surveyAddres;
    self.postalCode = persist_surveyPostalCode;
    self.blockId = persist_surveyBlockId;
    
    self.areaTxtFld.text = persist_specifyArea;
    self.residentNameTxFld.text = persist_residentName;
    [self.ageBtn setTitle:persist_age forState:UIControlStateNormal];
    
    //gender
    UIButton *femBtn = (UIButton *)[self.view viewWithTag:2];
    UIButton *maleBtn = (UIButton *)[self.view viewWithTag:1];
    
    if([persist_gender isEqualToString:@"M"])
    {
        
        self.gender = @"M";
        [maleBtn setSelected:YES];
        [femBtn setSelected:NO];
    }
    else if([persist_gender isEqualToString:@"F"])
    {
        self.gender = @"F";
        [femBtn setSelected:YES];
    }
    else
    {
        self.gender = @"M";
        [maleBtn setSelected:YES];
        [femBtn setSelected:NO];
    }
    
    
    [self.raceBtn setTitle:persist_race forState:UIControlStateNormal];
    
    self.residentAddressTxtFld.text = persist_residentAddress;
    self.residentPostalCode = persist_residentPostalCode;
    self.residentBlockId = persist_residentBlockId;
    
    self.unitNoTxtFld.text = persist_unitNo;
    self.contactNoTxFld.text = persist_contact;
    self.otherContactNoTxFld.text = persist_otherContact;
    self.emailTxFld.text = persist_email;
}

- (void)generateData
{
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *block_noAndPostal = [NSString stringWithFormat:@"%@ %@",[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]] ;
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@ %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]];
            
            [self.addressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:street_name,@"DisplayText",obj,@"CustomObject",block_noAndPostal,@"DisplaySubText", nil]];
        }];
        
    });
}

#pragma mark MPGTextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //move resident textfield up to give more space for auto suggest
    if(textField.tag == 300)
    {
        CGRect residentTextFieldRect = textField.frame;
        CGRect scrollViewFrame = self.scrollView.frame;
        
        [self.scrollView scrollRectToVisible:CGRectMake(scrollViewFrame.origin.x, residentTextFieldRect.origin.y - 10, scrollViewFrame.size.width, scrollViewFrame.size.height) animated:YES];
     
        residentBlockId = 0;
        self.residentPostalCode = @"-1";
        
        textField.text = @"";
        [textField becomeFirstResponder];
    }
    
    else if (textField.tag == 100) //survey address
    {
        blockId = 0;
        self.postalCode = @"-1";
        
        textField.text = @"";
        [textField becomeFirstResponder];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    int MAXLENGTH = 8;
    
    if (textField.tag == 1000 || textField.tag == 2000) //contact
    {
        NSUInteger oldLength = [textField.text length];
        NSUInteger replacementLength = [string length];
        NSUInteger rangeLength = range.length;
        
        NSUInteger newLength = oldLength - rangeLength + replacementLength;
        
        BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
        
        return newLength <= MAXLENGTH || returnKey;
    }
    
    return YES;
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (NSArray *)dataForPopoverInTextField:(MPGTextField *)textField
{
    return self.addressArray;
}

- (BOOL)textFieldShouldSelect:(MPGTextField *)textField
{
    return YES;
}

- (void)textField:(MPGTextField *)textField didEndEditingWithSelection:(NSDictionary *)result
{
    if([[result valueForKey:@"CustomObject"] isKindOfClass:[NSDictionary class]] == NO) //user typed some shit!
    {
        if([textField isEqual:self.surveyAddressTxtFld])
        {
            blockId = 0;
            self.postalCode = @"-1"; //because tree got 0 postal code
        }
        
        else if ([textField isEqual:self.residentAddressTxtFld])
        {
            residentBlockId = 0;
            self.residentPostalCode = @"-1"; //because tree got 0 postal code
        }
        
        return;
    }
    
    if([textField isEqual:self.surveyAddressTxtFld])
    {
        self.surveyAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
        
        blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
        self.postalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    }
    else if ([textField isEqual:self.residentAddressTxtFld])
    {
        self.residentAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
        
        residentBlockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
        self.residentPostalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleDisclame:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    if(btn.tag == 20) //decline
    {
        //update survey as data_protection = 0;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            db.traceExecution = NO;
            BOOL upSu = [db executeUpdate:@"update su_survey set data_protection = ? where client_survey_id = ?",[NSNumber numberWithInt:0],surveyId];
            if(!upSu)
            {
                *rollback = YES;
                return;
            }
        }];
    }
    else //proceed
    {
       //update survey as data_protection = 1;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL upSu = [db executeUpdate:@"update su_survey set data_protection = ? where client_survey_id = ?",[NSNumber numberWithInt:1],surveyId];
            if(!upSu)
            {
                *rollback = YES;
                return;
            }
        }];
    }
    
    self.disclaimerView.hidden = YES;
    
    didTakeActionOnDataPrivacyTerms = YES;
    
    self.title = @"Resident Information";
    
    if(resumeSurvey == NO) //survey is resumed, we don't need to get current location. user must input it manually
        [self preFillOtherInfo];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.currentClientSurveyId =  [NSNumber numberWithLongLong:currentSurveyId];
        fvc.postalCode = self.postalCode;
        fvc.residentPostalCode = self.residentPostalCode;
    }
    else if([segue.identifier isEqualToString:@"push_survey_detail"])
    {
        SurveyDetailViewController *surveyDetail = [segue destinationViewController];
        surveyDetail.clientSurveyId = [NSNumber numberWithLongLong:currentSurveyId];
        surveyDetail.pushFromResidentInfo = YES;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //by default hide the action button until user agree to proceed
    self.navigationController.navigationItem.rightBarButtonItem.width = 0.01;
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.5);
    
    if(didAddFeedBack)
    {
        [self action:self];
    }
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
            self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 2);
        else
            self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.5);
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"backButtonWasPressedFromResidentInfo" object:nil];
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [locationManager stopUpdatingLocation];
    
    [super viewWillDisappear:animated];
}

- (void)preFillOtherInfo
{
    NSDictionary *topLocation = [foundPlacesArray firstObject];
    
    self.surveyAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.residentAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.postalCode = [topLocation valueForKey:@"postal_code"];
    self.residentPostalCode = [topLocation valueForKey:@"postal_code"];
    self.blockId = [topLocation valueForKey:@"block_id"];
    self.residentBlockId = [topLocation valueForKey:@"block_id"];
    
    postInfoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyLocationsViewController"];
    postInfoVc.delegate = self;
    postInfoVc.foundPlacesArray = foundPlacesArray;
    
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:postInfoVc];
    
    formSheet.presentedFormSheetSize = CGSizeMake(300, 298);
    //    formSheet.transitionStyle = MZFormSheetTransitionStyleSlideFromTop;
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



#pragma mark - user tapped a nearby location from pop-up
-(void)selectedTableRowLocation:(NSNotification *)notif
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    
    NSNumber *row = [[notif userInfo] valueForKey:@"row"];
    int rowNum = [row intValue];
    
    self.surveyAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_no"],[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"street_name"]] ;
    self.residentAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_no"],[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"street_name"]];
    
    self.postalCode = [[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"postal_code"];
    self.residentPostalCode = [[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"postal_code"];
    
    blockId = [[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_id"];
    residentBlockId = [[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_id"];
    
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        [self validatePostalCode];
    }];
}

- (void)closePopUpWithLocationReload:(NSNotification *)notif
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    
    BOOL reload = [[[notif userInfo] valueForKey:@"reload"] boolValue];
    
    if(reload)
    {
        self.foundPlacesArray = nil;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Capturing location...";
        
        self.dismissPopupByReload = YES;
        
        //init location manager
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = 100;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        
        [locationManager requestAlwaysAuthorization];
        [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
        
        [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
            [self performSelector:@selector(locationReloaded) withObject:nil afterDelay:7.0];
        }];
    }
    else
    {
        [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
            [self validatePostalCode];
        }];
    }
}

- (void)locationReloaded
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    
    [self preFillOtherInfo];
}

#pragma mark - location manager
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    
    BOOL locationIsGood = YES;
    
    if (locationAge > 15.0)
    {
        locationIsGood = NO;
    }
    
    if (loc.horizontalAccuracy < 0)
    {
        locationIsGood = NO;
    }
    
    if(locationIsGood)
    {
        self.currentLocation = loc;
        self.currentLocationFound = YES;
        [locationManager stopUpdatingLocation];
        
        [self getNearbyBlocksWithinTheGrcForThisLocation:loc];
    }
}

- (void)getNearbyBlocksWithinTheGrcForThisLocation:(CLLocation *)location
{
    double current_lat = location.coordinate.latitude;
    double current_lng = location.coordinate.longitude;
    
//    double current_lat = 1.301435;
//    double current_lng = 103.797132;
    
    self.closeAreas = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *nearestBlocks = [db executeQuery:@"select * from blocks where latitude > 0 and longitude > 0"];
        
        while ([nearestBlocks next]) {
            
            NSDictionary *dict = [nearestBlocks resultDictionary];
            
            double lat = [nearestBlocks doubleForColumn:@"latitude"];
            double lng = [nearestBlocks doubleForColumn:@"longitude"];
            
            double distance = (acos(sin(current_lat * M_PI / 180) * sin(lat * M_PI / 180) + cos(current_lat * M_PI / 180) * cos(lat * M_PI / 180) * cos((current_lng - lng) * M_PI / 180)) * 180 / M_PI) * 60 * 1.1515 * 1.609344;
            
            double distanceInMeters = distance * 1000;
            
            if(distanceInMeters <= 500) //500 m
            {
                [self.closeAreas addObject:dict];
            }
        }
        
        self.foundPlacesArray = self.closeAreas;
    }];
}

- (void)validatePostalCode
{
    __block BOOL validPostalCode = NO;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select postal_code from blocks where postal_code = ?",self.postalCode];
        
        if([rs next] == YES)
        {
            validPostalCode = YES;
        }
    }];
    
    if(validPostalCode == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:@"Survey address is not within your GRC, Please select a valid address by typing inside the Survey address field" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        alert.tag = 100;
        [alert show];
    }
}

- (IBAction)selectAge:(id)sender
{
    [self.view endEditing:YES];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Contract type" rows:self.ageRangeArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        [self.ageBtn setTitle:[NSString stringWithFormat:@" %@",[self.ageRangeArray objectAtIndex:selectedIndex]] forState:UIControlStateNormal];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}


- (IBAction)selectRace:(id)sender
{
    [self.view endEditing:YES];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Contract type" rows:self.raceArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        [self.raceBtn setTitle:[NSString stringWithFormat:@" %@",[self.raceArray objectAtIndex:selectedIndex]] forState:UIControlStateNormal];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}

-(IBAction)toggelGender:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    UIButton *femBtn = (UIButton *)[self.view viewWithTag:2];
    UIButton *maleBtn = (UIButton *)[self.view viewWithTag:1];
    
    int tag = (int)btn.tag;
    
    
    [btn setSelected:!btn.selected];
    
    if(tag == 1) //male
    {
        
        self.gender = @"M";
        
        [maleBtn setSelected:YES];
        [femBtn setSelected:NO];
    }
    else
    {
        self.gender = @"F";
        
        [femBtn setSelected:YES];
        [maleBtn setSelected:NO];
    }
}

//this method is replaced by - (IBAction)residentInfoAction:(id)sender
- (IBAction)action:(id)sender
{
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action" message:@"Select what to do next" delegate:self cancelButtonTitle:@"Edit Resident Info" otherButtonTitles:@"Add more feedback",@"Complete this survey", nil];
    
    [alert show];
    
    didAddFeedBack = NO; //so this alert will not show again when VC is popped
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        
    }
    else
    {
        if(buttonIndex == 1)
        {
            
            [self saveResidentAdressWithSegueToFeedback:YES forBtnAction:@"feedback"];
        }
        else if(buttonIndex == 2)
        {
            [self surveyIsCompletedUpdateTheStatus];
            //[self saveResidentAdressWithSegueToFeedback:NO forBtnAction:@"done"];
        }
    }
    
}

- (IBAction)residentInfoAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    if (btn.tag == 1)
    {

        [self saveResidentAdressWithSegueToFeedback:YES forBtnAction:@"feedback"];
    }


    else
    {
        [self saveResidentAdressWithSegueToFeedback:NO forBtnAction:@"done"];
    }
}

//this method is called when the pop-up action and selected Complete this survey
- (void)surveyIsCompletedUpdateTheStatus
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL up = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ? ",[NSNumber numberWithInt:1],[NSNumber numberWithLongLong:currentSurveyId]];
        
        if(!up)
        {
            *rollback = YES;
            return;
        }
        
        //survey is Done!
        //upload this survey
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Synchronize *sync = [Synchronize sharedManager];
            [sync uploadSurveyFromSelf:NO];
        });
        
        didAddFeedBack = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchSurveyNewSurveyNotification" object:nil];
    
    [self performSegueWithIdentifier:@"push_survey_detail" sender:self];
}

- (void)saveResidentAdressWithSegueToFeedback:(BOOL)goToFeedback forBtnAction:(NSString *)action
{
    NSString *theEmail = [self.emailTxFld.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(theEmail.length > 0 && theEmail != nil)
    {
        if([self NSStringIsValidEmail:theEmail] == NO)
        {
            okToSubmitForm = NO;
            formErrorMsg = @"Invalid email address format.";
        }
        else
            okToSubmitForm = YES;
    }
    else if(theEmail.length == 0)
        okToSubmitForm = YES;
    
    
    if(okToSubmitForm == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Resident Information" message:formErrorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        
        [alert show];
        
        return;
    }

    didAddFeedBack = YES;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *survey_date = [NSDate date];
        NSString *resident_name = self.residentNameTxFld.text;
        NSString *resident_age_range = self.ageBtn.titleLabel.text;
        NSString *resident_gender = self.gender;
        NSString *resident_race = self.raceBtn.titleLabel.text;
        NSNumber *average_rating = averageRating;
        NSString *resident_contact = self.contactNoTxFld.text;
        NSString *other_resident_contact = self.otherContactNoTxFld.text;
        NSString *resident_email = self.emailTxFld.text;
        
        BOOL up = NO;

        long long lastSurveyAddressId = 0;
        long long lastResidentAddressId = 0;
        
        if(self.surveyAddressTxtFld.text != nil && self.surveyAddressTxtFld.text.length > 0 && ![self.postalCode isEqualToString:@"-1"] && self.postalCode.length > 0 && blockId != 0)
        {
            
            
            BOOL insSurveyAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area, postal_code, block_id) values (?,?,?,?,?)",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.postalCode, blockId];
            
            if(!insSurveyAddress)
            {
                *rollback = YES;
                return;
            }
        
            lastSurveyAddressId = [db lastInsertRowId];
            
        }
        else
        {
            [myDatabase alertMessageWithMessage:@"Please select a valid survey address within the GRC"];
            return;
        }
        
        
        if(self.residentAddressTxtFld.text != nil && self.residentAddressTxtFld.text.length > 0)
        {
            BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area,postal_code, block_id) values (?,?,?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.residentPostalCode, residentBlockId];
            
            if(!insResidentAddress)
            {
                *rollback = YES;
                return;
            }
        
            lastResidentAddressId = [db lastInsertRowId];

        }
        
        
        //get survey address
        FMResultSet *rsSurveyAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithLongLong:lastSurveyAddressId]];
        NSDictionary *surveyAddressDict;
        
        while ([rsSurveyAddress next]) {
            surveyAddressDict = [rsSurveyAddress resultDictionary];
        }
        
        //get resident address
        FMResultSet *rsResidentAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithLongLong:lastResidentAddressId]];
        NSDictionary *residentAddressDict;
        
        while ([rsResidentAddress next]) {
            residentAddressDict = [rsResidentAddress resultDictionary];
        }
        
        
        //update su_survey
        NSNumber *client_survey_address_id = [NSNumber numberWithInt:[[surveyAddressDict valueForKey:@"client_address_id"] intValue]];
        NSNumber *client_resident_address_id = [NSNumber numberWithInt:[[residentAddressDict valueForKey:@"client_address_id"] intValue]];
        
        
        up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, survey_date = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, average_rating = ?, resident_contact = ?, resident_email = ?,other_contact = ? where client_survey_id = ?",client_survey_address_id,survey_date,resident_name,resident_age_range,resident_gender,resident_race,client_resident_address_id,average_rating,resident_contact,resident_email,other_resident_contact,[NSNumber numberWithLongLong:currentSurveyId]];
        
        if(!up)
        {
            *rollback = YES;
            return;
        }
        
        if ([action isEqualToString:@"done"])
        {
            up = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ? ",[NSNumber numberWithInt:1],[NSNumber numberWithLongLong:currentSurveyId]];
            
            //survey is Done!
            //upload this survey
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Synchronize *sync = [Synchronize sharedManager];
                [sync uploadSurveyFromSelf:NO];
            });
            
            didAddFeedBack = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchSurveyNewSurveyNotification" object:nil];
        }
        
        if(goToFeedback)
        {
            //our survey is not yet finish so update the survey status to 0 w/c means upload is not required
            BOOL up = [db executeUpdate:@"update su_survey set status = ?  where client_survey_id = ?",[NSNumber numberWithInt:0],[NSNumber numberWithLongLong:currentSurveyId]];
            
            if(!up)
            {
                *rollback = YES;
                return;
            }
            
            [self performSegueWithIdentifier:@"push_feedback" sender:self];
        }
        
        else
            [self performSegueWithIdentifier:@"push_survey_detail" sender:self];
    }];
    
    
}


@end
