//
//  FeedBackViewController.m
//  comress
//
//  Created by Diffy Romano on 4/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedBackViewController.h"

@interface FeedBackViewController ()
{
    BOOL didInterActWithOthersAddressTxtFld;
}

@property (nonatomic, strong) NSNumber *surveyAddressId;
@property (nonatomic, strong) NSNumber *residentAddressId;

@end

@implementation FeedBackViewController

@synthesize currentClientSurveyId,pushFromSurvey,pushFromSurveyDetail,postalCode,pushFromSurveyAndModalFromFeedback,blockId,surveyAddressId,residentAddressId,autoAssignToMeMaintenance,autoAssignToMeOthers,residentPostalCode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    blocks = [[Blocks alloc] init];
    
    self.crmAssignArray = [NSArray arrayWithObjects:@"My self",@"General CRM", nil];
    
    autoAssignToMeMaintenance = YES;
    autoAssignToMeOthers = YES;
    
    //default selection
    self.selectedFeedBackLoc = @"survey";
    UIButton *btnSurveyDef = (UIButton *)[self.view viewWithTag:11];
    [btnSurveyDef setSelected:YES];
    
    //get the client_survey_address_id and client_resident_address_id from survey using self.currentClientSurveyId
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsAdd = [db executeQuery:@"select * from su_survey where client_survey_id = ?",self.currentClientSurveyId];
       

        NSNumber *zero = [NSNumber numberWithInt:0];

        while ([rsAdd next]) {
            surveyAddressId = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_survey_address_id"]];
            residentAddressId = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_resident_address_id"]];
        }
        
        if (surveyAddressId == zero && residentAddressId == zero) {
            self.selectedFeedBackLoc = @"others";
            
            //check the 'Others' radio button
            UIButton *btnSurvey = (UIButton *)[self.view viewWithTag:11];
            UIButton *btnResident = (UIButton *)[self.view viewWithTag:12];
            UIButton *btnOthers = (UIButton *)[self.view viewWithTag:13];
            
            [btnSurvey setSelected:NO]; //reset to radio off. default is radio on
            [btnResident setSelected:NO];
            [btnOthers setSelected:YES];
            
            //disable survey and resident btn
            btnSurvey.enabled = NO;
            btnResident.enabled = NO;
        }
    }];
    
    
    //by default, pre-fill the Others textfield with survey address
    __block NSString *defSurveyAddress;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsGetAdd = [db executeQuery:@"select * from su_address where client_address_id = ?",surveyAddressId];
        while ([rsGetAdd next]) {
            defSurveyAddress = [rsGetAdd stringForColumn:@"address"];
            postalCode = [rsGetAdd stringForColumn:@"postal_code"];
        }
    }];
    self.othersAddTxtField.text = defSurveyAddress;
    
    
    
    //validate if the postalCode is within the GRC
    __block BOOL invalidSurveyPostalCode = NO;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from blocks where postal_code = ?",self.postalCode];
        
        if([rs next] == NO) //does not exist
        {
            invalidSurveyPostalCode = YES;
        }
    }];
    
    if(invalidSurveyPostalCode == YES)
    {
        UIButton *btn = (UIButton *)[self.view viewWithTag:11];
        btn.enabled = NO;
    }
    
    
    //validate if the self.residentPostalCode is within the GRC
    __block BOOL invalidResidentPostalCode = NO;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from blocks where postal_code = ?",self.residentPostalCode];
        
        if([rs next] == NO) //does not exist
        {
            invalidResidentPostalCode = YES;
        }
    }];
    
    if(invalidResidentPostalCode == YES)
    {
        UIButton *btn = (UIButton *)[self.view viewWithTag:12];
        btn.enabled = NO;
    }
    
    if(invalidSurveyPostalCode && invalidResidentPostalCode)
    {
        //disable the others address textfield until the user select Others address radio button
        MPGTextField *othersTextField = (MPGTextField *)[self.view viewWithTag:300];
        othersTextField.userInteractionEnabled = YES;
        othersTextField.backgroundColor = [UIColor whiteColor];
    }
    else
    {
        //disable the others address textfield until the user select Others address radio button
        MPGTextField *othersTextField = (MPGTextField *)[self.view viewWithTag:300];
        othersTextField.userInteractionEnabled = NO;
        othersTextField.backgroundColor = [UIColor lightGrayColor];
    }
    
    self.selectedFeeBackTypeArr = [[NSMutableArray alloc] init];
    self.selectedFeeBackTypeStringArr = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(push_survey_detail:) name:@"push_survey_detail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(go_back_to_survey) name:@"go_back_to_survey" object:nil];
    
    [self generateData];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //move resident textfield up to give more space for auto suggest
    if(textField.tag == 300)
    {
        didInterActWithOthersAddressTxtFld = YES;
        
        CGRect residentTextFieldRect = textField.frame;
        CGRect scrollViewFrame = self.scrollView.frame;
        
        [self.scrollView scrollRectToVisible:CGRectMake(scrollViewFrame.origin.x, residentTextFieldRect.origin.y - 10, scrollViewFrame.size.width, scrollViewFrame.size.height) animated:YES];
        
        textField.text = @"";
        
        [textField becomeFirstResponder];
    }
    else
        didInterActWithOthersAddressTxtFld = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    didInterActWithOthersAddressTxtFld = NO;
}

#pragma mark MPGTextField Delegate Methods

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
        postalCode = @"-1";
        return;
    }
    
    
    self.othersAddTxtField.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
    
    blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
    postalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
}


- (void)go_back_to_survey
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)push_survey_detail:(NSNotification *)notif
{
    NSNumber *surveyId = [[notif userInfo] valueForKey:@"surveyId"];
    
    [self performSegueWithIdentifier:@"push_survey_detail" sender:surveyId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"modal_create_issue"])
    {
        Survey *survey = [[Survey alloc] init];
        NSDictionary *dict = [survey surveyForId:currentClientSurveyId forAddressType:self.selectedFeedBackLoc];
        
        NSMutableString *contractString = [[NSMutableString alloc] init];
        
        for (int i = 0; i < self.selectedFeeBackTypeStringArr.count; i++) {
            NSString *str = [self.selectedFeeBackTypeStringArr objectAtIndex:i];
            [contractString appendString:[NSString stringWithFormat:@"%@, ",str]];
        }
        
        if([self.selectedCrmAssignmentForMaintenance isEqualToString:@"General CRM"])
            autoAssignToMeMaintenance = NO;
        
        if([self.selectedCrmAssignmentForOthers isEqualToString:@"General CRM"])
            autoAssignToMeOthers = NO;
        
        CreateIssueViewController *cvc = [segue destinationViewController];
        cvc.surveyId = currentClientSurveyId;
        cvc.feedBackId = sender;
        cvc.surveyDetail = dict;
        cvc.postalCode = postalCode;
        cvc.selectedContractTypesArr = self.selectedFeeBackTypeArr;
        cvc.selectedContractTypesString = contractString;
        cvc.crmAutoAssignToMeMaintenance = autoAssignToMeMaintenance;
        cvc.crmAutoAssignToMeOthers = autoAssignToMeOthers;
        cvc.feedBackDescription = self.feedBackTextView.text;
        cvc.blockId = blockId;
        
        if(pushFromSurveyAndModalFromFeedback)
            cvc.pushFromSurveyAndModalFromFeedback = YES;
    }
    
    if([segue.identifier isEqualToString:@"push_survey_detail"])
    {
        self.tabBarController.tabBar.hidden = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBar.hidden = NO;
        
        SurveyDetailViewController *sdvc = [segue destinationViewController];
        NSNumber *surveyId = sender;
        sdvc.surveyId = surveyId;
        sdvc.pushFromIssue = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //only if push from survey since survey is in landscape mode
    if(pushFromSurvey)
    {
//        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    if(pushFromSurveyDetail == NO)
        self.navigationItem.hidesBackButton = YES;
    
    if(pushFromSurveyDetail == YES)
    {
        self.segment.hidden = YES;
        self.title = @"New Feedback";
    }
    
    //add border to the textview
    [[self.feedBackTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.feedBackTextView layer] setBorderWidth:1];
    [[self.feedBackTextView layer] setCornerRadius:15];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.5);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(didInterActWithOthersAddressTxtFld == NO) // only dismiss the keyboard when interacting with others address textfield
        [self.view endEditing:YES];
}

-(IBAction)toggleSegment:(id)sender
{
    if(self.segment.selectedSegmentIndex == 0)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (IBAction)toggleFeedBackLocation:(id)sender
{
    UIButton *sur = (UIButton *)[self.view viewWithTag:11];
    UIButton *res = (UIButton *)[self.view viewWithTag:12];
    UIButton *oth = (UIButton *)[self.view viewWithTag:13];

    UIButton *btn = (UIButton *)sender;
    
    int tag = (int)btn.tag;
    
    [btn setSelected:!btn.selected];
    
    if(tag == 11)
    {
        [sur setSelected:YES];
        [res setSelected:NO];
        [oth setSelected:NO];
        
        self.selectedFeedBackLoc = @"survey";
        
        __block NSString *defSurveyAddress;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetAdd = [db executeQuery:@"select * from su_address where client_address_id = ?",surveyAddressId];
            while ([rsGetAdd next]) {
                defSurveyAddress = [rsGetAdd stringForColumn:@"address"];
                postalCode = [rsGetAdd stringForColumn:@"postal_code"];
            }
            
            //get the block id of this postal code
            FMResultSet *rsGetBlockId = [db executeQuery:@"select * from blocks where postal_code = ?",postalCode];
            while ([rsGetBlockId next]) {
                blockId = [NSNumber numberWithInt:[rsGetBlockId intForColumn:@"block_id"]];
            }
        }];
        self.othersAddTxtField.text = defSurveyAddress;
        
        MPGTextField *othersTextField = (MPGTextField *)[self.view viewWithTag:300];
        othersTextField.userInteractionEnabled = NO;
        othersTextField.backgroundColor = [UIColor lightGrayColor];
        
    }
    else if (tag == 12)
    {
        [res setSelected:YES];
        [sur setSelected:NO];
        [oth setSelected:NO];
        
        self.selectedFeedBackLoc = @"resident";
        
        postalCode = self.residentPostalCode;
        
        __block NSString *defResidentAddress;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetAdd = [db executeQuery:@"select * from su_address where client_address_id = ?",residentAddressId];
            while ([rsGetAdd next]) {
                defResidentAddress = [rsGetAdd stringForColumn:@"address"];
                postalCode = [rsGetAdd stringForColumn:@"postal_code"];
            }
            
            //get the block id of this postal code
            FMResultSet *rsGetBlockId = [db executeQuery:@"select * from blocks where postal_code = ?",postalCode];
            while ([rsGetBlockId next]) {
                blockId = [NSNumber numberWithInt:[rsGetBlockId intForColumn:@"block_id"]];
            }
        }];
        
        postalCode = self.residentPostalCode;
        
        self.othersAddTxtField.text = defResidentAddress;
        
        MPGTextField *othersTextField = (MPGTextField *)[self.view viewWithTag:300];
        othersTextField.userInteractionEnabled = NO;
        othersTextField.backgroundColor = [UIColor lightGrayColor];
        
    }
    else if (tag == 13)
    {
        [oth setSelected:YES];
        [res setSelected:NO];
        [sur setSelected:NO];
        
        self.selectedFeedBackLoc = @"others";
        self.othersAddTxtField.text = @"";
        postalCode = @"-1";
        self.residentPostalCode = @"-1";
        
        MPGTextField *othersTextField = (MPGTextField *)[self.view viewWithTag:300];
        othersTextField.userInteractionEnabled = YES;
        othersTextField.backgroundColor = [UIColor whiteColor];
    }
}

- (IBAction)selectFeedbackType:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    UIButton *btnCons = (UIButton *)[self.view viewWithTag:1];
    UIButton *btnHort = (UIButton *)[self.view viewWithTag:2];
    UIButton *btnPump = (UIButton *)[self.view viewWithTag:4];
    UIButton *btnMain = (UIButton *)[self.view viewWithTag:6];
    UIButton *btnOthers = (UIButton *)[self.view viewWithTag:7];
    
    
    if([self.selectedFeeBackTypeArr containsObject:tag] == NO)
    {
        [self.selectedFeeBackTypeArr addObject:tag];
    }
    else
    {
        [self.selectedFeeBackTypeArr removeObject:tag];
    }
    
    
    if([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:19]]) //none
    {
        [self.selectedFeeBackTypeArr removeAllObjects];
        [self.selectedFeeBackTypeStringArr removeAllObjects];
        
        [self.selectedFeeBackTypeArr addObject:tag];
        
        [btnCons setSelected:NO];
        [btnHort setSelected:NO];
        [btnPump setSelected:NO];
        [btnMain setSelected:NO];
        [btnOthers setSelected:NO];
        
        btnCons.enabled = NO;
        btnHort.enabled = NO;
        btnPump.enabled = NO;
        btnMain.enabled = NO;
        btnOthers.enabled = NO;
    }
    else
    {
        btnCons.enabled = YES;
        btnHort.enabled = YES;
        btnPump.enabled = YES;
        btnMain.enabled = YES;
        btnOthers.enabled = YES;
    }
    
    
    //configure!
    //add contract type strings
    NSString *contractypeString;
    int intTag = [tag intValue];
    switch (intTag) {
        case 1:
            contractypeString = @"Conservancy";
            break;
            
        case 2:
            contractypeString = @"Horticulture";
            break;
            
        case 4:
            contractypeString = @"Pump";
            break;
            
        case 6:
            contractypeString = @"Maintenance";
            break;
            
        case 7:
            contractypeString = @"Others";
            break;
            
        default: //19
            contractypeString = @"None";
            break;
    }
    
    if([self.selectedFeeBackTypeStringArr containsObject:contractypeString] == NO)
    {
        [self.selectedFeeBackTypeStringArr addObject:contractypeString];
    }
    else
    {
        [self.selectedFeeBackTypeStringArr removeObject:contractypeString];
    }
    
    [btn setSelected:!btn.selected];
}


- (IBAction)addFeedBack:(id)sender
{
    [self.view endEditing:YES];
    
    BOOL onlyNoneIsSelectedDontCreateIssue = NO;
    if(self.selectedFeeBackTypeArr.count == 0)
        onlyNoneIsSelectedDontCreateIssue = YES;
    
    if(onlyNoneIsSelectedDontCreateIssue == YES)
    {
        [self saveFeedBack];
    }
    else
    {
        BOOL allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = NO;
        
        if([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:6]] && [self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:7]])
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        else if ([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:6]] && self.selectedFeeBackTypeArr.count == 1)
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        
        else if ([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:7]] && self.selectedFeeBackTypeArr.count == 1)
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        
        
        //do we have post?
        int postCounter = 0;
        for (int i = 0; i < self.selectedFeeBackTypeArr.count; i++) {
            NSNumber *postType = [self.selectedFeeBackTypeArr objectAtIndex:i];
            
            if([postType intValue] == 1 || [postType intValue] == 2 || [postType intValue] == 4)
            {
                postCounter++;
            }
        }
        
        NSString *message;
        
        if(allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue == YES)
            message = @"Save feedback and raise this issue(s)?";
        else
            message = [NSString stringWithFormat:@"Are you sure you want to create %d issues?",postCounter];
            
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        
        [alert show];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1) //YES!
    {
        [self saveFeedBack];
    }
}


- (void)saveFeedBack
{
    //save feedback!
    __block NSNumber *feedBackId;
    __block BOOL feedbackSaved = NO;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        //get the client_survey_address_id and client_resident_address_id from survey using self.currentClientSurveyId
        
        FMResultSet *rsAdd = [db executeQuery:@"select * from su_survey where client_survey_id = ?",self.currentClientSurveyId];
        NSNumber *client_survey_address_id;
        NSNumber *client_resident_address_id;
        
        while ([rsAdd next]) {
            client_survey_address_id = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_survey_address_id"]];
            client_resident_address_id = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_resident_address_id"]];
        }
        
        
        NSNumber *client_address_id;
        
        if([self.selectedFeedBackLoc isEqualToString:@"survey"])
        {
            client_address_id = client_survey_address_id;
        }
        else if ([self.selectedFeedBackLoc isEqualToString:@"resident"])
        {
            client_address_id = client_resident_address_id;
        }
        else
        {
            //get address info of this client_address_id
            FMResultSet *rsAddInfo = [db executeQuery:@"select * from su_address where client_address_id = ?",client_address_id];
            
            NSDictionary *dictAddInfo;
            
            while ([rsAddInfo next]) {
                dictAddInfo = [rsAddInfo resultDictionary];
            }
            
            if(self.othersAddTxtField.text != nil && self.othersAddTxtField.text.length > 0 && ![postalCode isEqualToString:@"-1"] && blockId != 0)
            {
                //save the 'Others' address
                BOOL ins = [db executeUpdate:@"insert into su_address(address,unit_no,specify_area,postal_code,block_id) values (?,?,?,?,?)",self.othersAddTxtField.text,[dictAddInfo valueForKey:@"unit_no"],[dictAddInfo valueForKey:@"specify_area"],postalCode,blockId];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
                
                client_address_id = [NSNumber numberWithLongLong:[db lastInsertRowId]];
            }
            else
            {
                [myDatabase alertMessageWithMessage:@"Please select a valid Feedback location."];
                return;
            }
        }
        
        //finally, save the feedback
        
        BOOL insFeedBack = [db executeUpdate:@"insert into su_feedback (client_survey_id,description,client_address_id) values (?,?,?)",currentClientSurveyId,self.feedBackTextView.text,client_address_id];
        
        if(!insFeedBack)
        {
            *rollback = YES;
            return;
        }
        else
        {
            feedbackSaved = YES;
            
            feedBackId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
        }
    }];
    
    
    if(feedbackSaved)
    {
        //check self.selectedFeeBackTypeArr
        
        BOOL allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = NO;
        
        if([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:6]] && [self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:7]] && self.selectedFeeBackTypeArr.count == 2)
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        else if ([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:6]] && self.selectedFeeBackTypeArr.count == 1)
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        
        else if ([self.selectedFeeBackTypeArr containsObject:[NSNumber numberWithInt:7]] && self.selectedFeeBackTypeArr.count == 1)
        {
            allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue = YES;
        }
        
        
        BOOL onlyNoneIsSelectedDontCreateIssue = NO;
        if(self.selectedFeeBackTypeArr.count == 0)
            onlyNoneIsSelectedDontCreateIssue = YES;
        
        if(allAreCrmDontCreateIssuAndInsertDirectylyToFeedbackIssue)
        {
            //now we allow crm to go to create issue page
            [self performSegueWithIdentifier:@"modal_create_issue" sender:feedBackId];
        }
        
        else if (onlyNoneIsSelectedDontCreateIssue)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        else //could be all comress issues or combination of crm and or combination of all
        {
            //segue to issues and pass selected contract types;
            [self performSegueWithIdentifier:@"modal_create_issue" sender:feedBackId];
        }
    }
}

- (IBAction)crmAssign:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    [self.view endEditing:YES];
    
    if(btn.tag == 1)
    {
        if(autoAssignToMeMaintenance == YES)
        {
            autoAssignToMeMaintenance = NO;
            [btn setTitle:@"General Crm" forState:UIControlStateNormal];
        }

        else
        {
            autoAssignToMeMaintenance = YES;
            [btn setTitle:@"My self" forState:UIControlStateNormal];
        }
        
        

    }
    else
    {
        if(autoAssignToMeOthers == YES)
        {
            autoAssignToMeOthers = NO;
            [btn setTitle:@"General Crm" forState:UIControlStateNormal];
        }
        
        else
        {
            autoAssignToMeOthers = YES;
            [btn setTitle:@"My self" forState:UIControlStateNormal];
        }
        
    }
}



@end
