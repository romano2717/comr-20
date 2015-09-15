//
//  ResidentPopInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 7/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentPopInfoViewController.h"
#import "Synchronize.h"

@interface ResidentPopInfoViewController ()

@property (nonatomic) BOOL okToSubmitForm;
@property (nonatomic, strong) NSString *formErrorMsg;

@end

@implementation ResidentPopInfoViewController

@synthesize surveyId,blockId,clientSurveyId,okToSubmitForm,formErrorMsg,residentBlockId,residentAddressIsNew;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    mySurvey = [[Survey alloc] init];
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    okToSubmitForm = YES;
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    NSDictionary *dict = [mySurvey surveDetailForId:surveyId forClientSurveyId:clientSurveyId];
    
    NSDictionary *surveyDict = [dict objectForKey:@"survey"];
    NSDictionary *residentAddressDict = [dict objectForKey:@"residentAddress"];
    NSDictionary *surveyAddressDict = [dict objectForKey:@"surveyAddress"];
    
    self.client_resident_address_id = [[surveyDict valueForKey:@"client_resident_address_id"] longLongValue];
    self.client_survey_address_id = [[surveyDict valueForKey:@"client_survey_address_id"] longLongValue];
    self.surveyAddressPostalCode = [surveyAddressDict valueForKey:@"postal_code"];
    
    residentBlockId = 0;
    if([residentAddressDict valueForKey:@"block_id"] != [NSNull null])
        residentBlockId = [NSNumber numberWithInt:[[residentAddressDict valueForKey:@"block_id"] intValue]];
    
    self.residentAddressPostalCode = [residentAddressDict valueForKey:@"postal_code"];

    NSString *surveyAddress;
    NSString *area;
    NSString *residentName;
    NSString *ageRange;
    NSString *genderSel;
    NSString *raceSel;
    NSString *residentAddress;
    NSString *unitNo;
    NSString *contact;
    NSString *otherContact;
    NSString *email;
    
    if([surveyAddressDict valueForKey:@"address"] != [NSNull null] && [surveyAddressDict valueForKey:@"address"] != nil)
        surveyAddress = [surveyAddressDict valueForKey:@"address"];
    
    if([surveyAddressDict valueForKey:@"specify_area"] != [NSNull null] && [surveyAddressDict valueForKey:@"specify_area"] != nil)
        area = [surveyAddressDict valueForKey:@"specify_area"];
    
    if([surveyDict valueForKey:@"resident_name"] != [NSNull null] && [surveyDict valueForKey:@"resident_name"] != nil)
        residentName = [surveyDict valueForKey:@"resident_name"];
    
    if([surveyDict valueForKey:@"resident_age_range"] != [NSNull null] && [surveyDict valueForKey:@"resident_age_range"] != nil)
        ageRange = [surveyDict valueForKey:@"resident_age_range"];
    
    if([surveyDict valueForKey:@"resident_gender"] != [NSNull null] && [surveyDict valueForKey:@"resident_gender"] != nil)
        genderSel = [surveyDict valueForKey:@"resident_gender"];
    
    if([surveyDict valueForKey:@"resident_race"] != [NSNull null] && [surveyDict valueForKey:@"resident_race"] != nil)
        raceSel = [surveyDict valueForKey:@"resident_race"];
    
    if([residentAddressDict valueForKey:@"address"] != [NSNull null] && [residentAddressDict valueForKey:@"address"] != nil)
        residentAddress = [residentAddressDict valueForKey:@"address"];
    
    if([residentAddressDict valueForKey:@"unit_no"] != [NSNull null] && [residentAddressDict valueForKey:@"unit_no"] != nil)
        unitNo = [residentAddressDict valueForKey:@"unit_no"];
    
    if([surveyDict valueForKey:@"resident_contact"] != [NSNull null] && [surveyDict valueForKey:@"resident_contact"] != nil)
        contact = [surveyDict valueForKey:@"resident_contact"];
    
    if([surveyDict valueForKey:@"other_contact"] != [NSNull null] && [surveyDict valueForKey:@"other_contact"] != nil)
        otherContact = [surveyDict valueForKey:@"other_contact"];
    
    if([surveyDict valueForKey:@"resident_email"] != [NSNull null] && [surveyDict valueForKey:@"resident_email"] != nil)
        email = [surveyDict valueForKey:@"resident_email"];
    

    self.surveyAddressTxtFld.text = surveyAddress;
    self.areaTxtFld.text = area;
    self.residentNameTxtFld.text = residentName;
    
    NSString *age = ageRange;
    [self.ageBtn setTitle:age forState:UIControlStateNormal];
    if([self.ageRangeArray containsObject:age])
        self.selectedAgeRange = age;
    
    NSString *gender = genderSel;
    UIButton *genderButtonToggleM = (UIButton *)[self.view viewWithTag:1];
    UIButton *genderButtonToggleF = (UIButton *)[self.view viewWithTag:2];

    if([gender isEqualToString:@"M"])
    {
        [genderButtonToggleM setSelected:YES];
        self.selectedGender = @"M";
    }
    else
    {
        [genderButtonToggleF setSelected:YES];
        self.selectedGender = @"F";
    }
    
    NSString *race = raceSel;
    [self.raceBtn setTitle:race forState:UIControlStateNormal];
    self.selectedRace = race;
    
    self.residentAddressTxtFld.text = residentAddress;
    self.unitNoTxtFld.text = unitNo;
    self.contactTxtFld.text = contact;
    self.otherContactTxtFld.text = otherContact;
    self.emailTxFld.text = email;
    
    
    
    //dismiss keyboard when dragged
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self generateData];
}


- (void)generateData
{
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *block_noAndPostal = [NSString stringWithFormat:@"%@ %@",[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]] ;
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"postal_code"]];
            
            [self.addressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:street_name,@"DisplayText",obj,@"CustomObject",block_noAndPostal,@"DisplaySubText", nil]];
        }];
        
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.5);
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
        
        self.client_resident_address_id = 0;
        self.residentAddressPostalCode = @"-1";
        residentBlockId = 0;
        
        textField.text = @"";
        [textField becomeFirstResponder];
    }
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
        self.client_resident_address_id = 0;
        self.residentAddressPostalCode = @"-1";
        residentBlockId = 0;
        return;
    }
    
    self.residentAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
    
    residentBlockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
    self.residentAddressPostalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        self.selectedGender = @"M";
        
        [maleBtn setSelected:YES];
        [femBtn setSelected:NO];
    }
    else
    {
        self.gender = @"F";
        self.selectedGender = @"F";
        
        [femBtn setSelected:YES];
        [maleBtn setSelected:NO];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender
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
    
    if(okToSubmitForm == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Resident Information" message:formErrorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        
        [alert show];
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *resident_name = self.residentNameTxtFld.text;
        NSString *resident_age_range = self.ageBtn.titleLabel.text;
        NSString *resident_gender = self.selectedGender;
        NSString *resident_race = self.raceBtn.titleLabel.text;

        NSString *resident_contact = self.contactTxtFld.text;
        NSString *resident_email = self.emailTxFld.text;
        NSString *other_contact = self.otherContactTxtFld.text;
        NSString *specify_area = self.areaTxtFld.text;
        
        //update specify area based on survey address id
        BOOL upSpecArea = [db executeUpdate:@"update su_address set specify_area = ? where client_address_id = ?",specify_area,[NSNumber numberWithLongLong:self.client_survey_address_id]];
        if(!upSpecArea)
        {
            *rollback = YES;
            return;
        }
        
        
        if(self.residentAddressTxtFld.text.length > 0 && self.residentAddressTxtFld.text != nil)
        {
            if(self.client_resident_address_id == 0)
            {
                BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area, postal_code, block_id) values (?,?,?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.residentAddressPostalCode,residentBlockId];
                
                if(!insResidentAddress)
                {
                    *rollback = YES;
                    return;
                }
                residentAddressIsNew = YES;
                self.client_resident_address_id = [db lastInsertRowId];
             
            }
            else
            {
                BOOL insResidentAddress = [db executeUpdate:@"update su_address set address = ?, unit_no = ?, specify_area = ?, postal_code = ?, block_id = ? where client_address_id = ?",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text,self.residentAddressPostalCode,residentBlockId, [NSNumber numberWithLongLong:self.client_resident_address_id]];
                
                if(!insResidentAddress)
                {
                    *rollback = YES;
                    return;
                }
            }
        }
        else
            self.client_resident_address_id = 0;
        
        NSNumber *theSurveyId = [NSNumber numberWithInt:0];
        if(clientSurveyId > 0)
            theSurveyId = clientSurveyId;
        else
            theSurveyId = surveyId;
        
        if(residentAddressIsNew == NO)
        {
            BOOL up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, resident_contact = ?, status = ?, resident_email = ?, other_contact = ? where client_survey_id = ?",[NSNumber numberWithLongLong:self.client_survey_address_id],resident_name,resident_age_range,resident_gender,resident_race,[NSNumber numberWithLongLong:self.client_resident_address_id],resident_contact,[NSNumber numberWithInt:1],resident_email,other_contact,theSurveyId];
            
            if(!up)
            {
                *rollback = YES;
                return;
            }
            else
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        else
        {
            BOOL up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?,resident_address_id = ?, resident_contact = ?, status = ?, resident_email = ?, other_contact = ? where client_survey_id = ?",[NSNumber numberWithLongLong:self.client_survey_address_id],resident_name,resident_age_range,resident_gender,resident_race,[NSNumber numberWithLongLong:self.client_resident_address_id],[NSNumber numberWithInt:0], resident_contact,[NSNumber numberWithInt:1],resident_email,other_contact,theSurveyId];
            
            if(!up)
            {
                *rollback = YES;
                return;
            }
            else
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber *theSurveyId = [NSNumber numberWithInt:0];
        if(clientSurveyId > 0)
            theSurveyId = clientSurveyId;
        else
            theSurveyId = surveyId;
        
        Synchronize *sync = [Synchronize sharedManager];
        [sync uploadResidentInfoEditForSurveyId:theSurveyId];
    });
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

@end
