//
//  CreateIssueViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CreateIssueViewController.h"
#import "Synchronize.h"

@interface CreateIssueViewController ()

@property (nonatomic, strong) NSMutableArray *photoArray;
@property (nonatomic, strong) NSMutableArray *photoArrayFull;
@property (nonatomic, strong) NSArray *severtiyArray;
@property (nonatomic, strong) NSArray *contractTypeArray;
@property (nonatomic, strong) NSArray *contractTypeArrayCopy;
@property (nonatomic, strong) NSMutableArray *blocksArray;
@property (nonatomic, strong) NSMutableArray *addressArray;

@end



@implementation CreateIssueViewController

@synthesize surveyId,surveyDetail,postalCode,postalCodeFound,blockId,selectedContractTypesArr,scrollView,pushFromSurveyAndModalFromFeedback,selectedContractTypesString,feedBackId,crmAutoAssignToMeMaintenance,crmAutoAssignToMeOthers,feedBackDescription;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    self.photoArray = [[NSMutableArray alloc] init];
    self.photoArrayFull = [[NSMutableArray alloc] init];
    
    self.severtiyArray = [NSArray arrayWithObjects:@"Routine",@"Severe", nil];
    
    //watch when keyboard is up/down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //keyboard can be dimiss by scrollview event
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    //set the severity by default to Routine
    [self.severityBtn setTitle:[NSString stringWithFormat:@" %@",[self.severtiyArray objectAtIndex:0]] forState:UIControlStateNormal];
    
    //add border to the textview
    [[self.descriptionTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.descriptionTextView layer] setBorderWidth:1];
    [[self.descriptionTextView layer] setCornerRadius:15];
    
    self.descriptionTextView.text = feedBackDescription;
    
    
    //check the address from feedback
    __block NSString *addressFromFeedBack;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsCheckAdd = [db executeQuery:@"select * from blocks where postal_code = ?",postalCode];
        while ([rsCheckAdd next]) {
            addressFromFeedBack = [rsCheckAdd stringForColumn:@"street_name"];
            postalCode = [rsCheckAdd stringForColumn:@"postal_code"];
        }
    }];
    self.addressTextField.text = addressFromFeedBack;
    self.postalCodeTextField.text = postalCode;
    
    
    
    [self generateData];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //search postal code here then auto fill in form if found. if not found, prompt user that postal code was not found. ask continue search/type or cancel
    if(postalCode != nil)
    {
        postalCodeFound = NO;
        __block NSString *postalCodeString = nil;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rs = [db executeQuery:@"select * from blocks where postal_code = ?",postalCode];
            
            if([rs next])
            {
                postalCodeString = [rs stringForColumn:@"postal_code"];
                postalCodeFound = YES;
            }
        }];
        
        if(postalCodeFound == NO)
        {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Issue" message:[NSString stringWithFormat:@"Postal code %@ was not found in our system. Continue to create issue by searching for the correct Postal Code",postalCode] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
            
            [alert show];
        }
        
        self.postalCodeTextField.text = postalCodeString ? postalCodeString : postalCode ;
        
        NSString *addressDictString = [[surveyDetail objectForKey:@"address"] valueForKey:@"address"];
        
        if([addressDictString isEqual:[NSNull null]] == NO && addressDictString != nil)
            self.addressTextField.text = addressDictString;
    }
    
    
    //pre-increase the contentsize of the scrollview to fit screen
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), self.scrollView.contentSize.height + 50);
    
    
    //display the selected contract types from feedback
    self.contractTypesLabel.text = selectedContractTypesString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cance:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveIssue:(id)sender
{
    if(postalCodeFound == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Issue" message:@"Cannot create issue for this postal code" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        
        [alert show];
    }
    else
    {
        
    }
}

- (void)generateData
{
    self.blocksArray = [[NSMutableArray alloc] init];
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *postal_code = [NSString stringWithFormat:@"%@ - %@",[obj valueForKey:@"postal_code"],[obj valueForKey:@"street_name"]];
            NSString *block_no = [obj valueForKey:@"block_no"];
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"postal_code"]];
            
            [self.blocksArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:postal_code,@"DisplayText",obj,@"CustomObject",block_no,@"DisplaySubText", nil]];
            
            [self.addressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:street_name,@"DisplayText",obj,@"CustomObject",block_no,@"DisplaySubText", nil]];
        }];
        
    });
}

#pragma mark MPGTextField Delegate Methods

- (NSArray *)dataForPopoverInTextField:(MPGTextField *)textField
{
    if ([textField isEqual:self.postalCodeTextField]) {
        return self.blocksArray;
    }
    else if ([textField isEqual:self.addressTextField])
    {
        return self.addressArray;
    }
    
    return nil;
    
}

- (BOOL)textFieldShouldSelect:(MPGTextField *)textField
{
    return YES;
}

- (void)textField:(MPGTextField *)textField didEndEditingWithSelection:(NSDictionary *)result
{
    if([[result valueForKey:@"CustomObject"] isKindOfClass:[NSDictionary class]] == NO) //user typed some shit!
        return;
    
    self.postalCodeTextField.text = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    self.addressTextField.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
    
    blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
    
}

- (void)keyboardWillChange:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect rect = [keyboardFrameBegin CGRectValue];
    
    //adjust scrollview contentsize so the keyboard will be just below the add photos button
    CGPoint addPhotosButtonPoint = CGPointMake(0, self.addPhotosButton.frame.origin.y);
    
    float buttonHeight = CGRectGetHeight(self.addPhotosButton.frame);
    float buttonYPos = addPhotosButtonPoint.y;
    
    float newScrollViewContentHeight = buttonYPos + buttonHeight;
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), newScrollViewContentHeight + rect.size.height);
}


- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_view_image"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        NSInteger index = indexPath.row;
        
        ImagePreviewViewController *imagPrev = [segue destinationViewController];
        
        imagPrev.image = (UIImage *)[self.photoArrayFull objectAtIndex:index];;
        
    }
}



#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.selected = YES;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    // Configure the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    imageView.image = (UIImage *)[self.photoArray objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    cell.contentView.backgroundColor = [UIColor blueColor];
    
    [self performSegueWithIdentifier:@"push_view_image" sender:indexPath];
}

# pragma mark uiactionsheet
- (IBAction)addPhotoActionSheet:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Add Photos" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera",@"Photo Library", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self openMediaByType:1];
            break;
            
        case 1:
            [self openMediaByType:2];
            break;
    }
    
    [self.view endEditing:YES];
}

#pragma mark image picker
- (void)openMediaByType:(int)type
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    if (type == 1)
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
    
    self.imagePicker = picker;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if(img == nil)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    imgOpts = [ImageOptions new];
    
    UIImage *thumbImage = [imgOpts resizeImageAsThumbnailForImage:img];
    
    [self.photoArray addObject:thumbImage];
    [self.photoArrayFull addObject:img];
    
    [self.collectionView reloadData];
}

#pragma mark scrollview delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

#pragma mark textfield delegate

- (IBAction)selectSeverity:(id)sender
{
    [self hideKeyboard:sender];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Severity" rows:self.severtiyArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        [self.severityBtn setTitle:[NSString stringWithFormat:@" %@",[self.severtiyArray objectAtIndex:selectedIndex]] forState:UIControlStateNormal];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)hidePickerView:(id)sender
{
    
}


#pragma mark Save new issue to local db
- (IBAction)postNewIssue:(id)sender
{
    NSString *postal_code = [self.postalCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *location = [self.addressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *level = [self.levelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *post_topic = [self.descriptionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *severity = [self.severityBtn.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //get the blockid of this postal code
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsBlkId = [db executeQuery:@"select * from blocks where postal_code = ?",postal_code];
        while ([rsBlkId next]) {
            blockId = [NSNumber numberWithInt:[rsBlkId intForColumn:@"block_id"]];
        }
    }];
    
    
    if(blockId ==  0 || blockId == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Issue" message:[NSString stringWithFormat:@"Postal code %@ was not found in our system. Continue to create issue by searching for the correct Postal Code",postalCode] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        
        [alert show];
        
        return;
    }
    
    user = [[Users alloc] init];
    post = [[Post alloc] init];
    postImage = [[PostImage alloc] init];
    

    for (int i = 0; i < selectedContractTypesArr.count; i ++) {
       
        NSNumber *contract_type_id = [selectedContractTypesArr objectAtIndex:i];
        
        __block NSNumber *clientFeedbackIssueId = [NSNumber numberWithInt:0];
        
        //save to su_feedback_issue
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            NSNumber *feedBackIssueIdForCrmDontNeedPostId = [NSNumber numberWithInt:0];
            
            if([contract_type_id intValue] == 6)
            {
                BOOL ins = [db executeUpdate:@"insert into su_feedback_issue (client_feedback_id,client_post_id,issue_des,auto_assignme) values (?,?,?,?)",feedBackId,feedBackIssueIdForCrmDontNeedPostId,@"CRM-MAINTENANCE",[NSNumber numberWithBool:crmAutoAssignToMeMaintenance]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return ;
                }
                else
                    clientFeedbackIssueId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
            }
            else if([contract_type_id intValue] == 7)
            {
                BOOL ins = [db executeUpdate:@"insert into su_feedback_issue (client_feedback_id,client_post_id,issue_des,auto_assignme) values (?,?,?,?)",feedBackId,feedBackIssueIdForCrmDontNeedPostId,@"CRM-OTHERS",[NSNumber numberWithBool:crmAutoAssignToMeOthers]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return ;
                }
                else
                    clientFeedbackIssueId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
            }
        }];
        
        if([contract_type_id intValue] == 6 || [contract_type_id intValue] == 7)
        {
            // create crm
            NSDictionary *crmDict = @{@"postal_code":postal_code,@"location":location,@"post_topic":post_topic,@"severity":severity,@"block_id":blockId,@"photoArray":self.photoArrayFull,@"clientFeedbackIssueId":clientFeedbackIssueId};
            
            [self createCrmWithDictionary:crmDict];
            

            if(i <= selectedContractTypesArr.count - 1) //last loop
            {
                [self dismissViewControllerAnimated:YES completion:^{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        Synchronize *sync = [Synchronize sharedManager];
                        [sync uploadSurveyFromSelf:NO];
                    });
                    
                    NSDictionary *surveyIdDict = @{@"surveyId":surveyId};
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"go_back_to_survey" object:nil userInfo:surveyIdDict];
                }];
            }
            
            //for crm, we don't need to create issue
            continue;
        }
        
        

        
        //----------- create issue -----------//
        

        if(postal_code.length == 0)
        {
            self.postalCodeLabel.backgroundColor = [UIColor redColor];
            return;
        }
        
        if(location.length == 0)
        {
            self.addressLabel.backgroundColor = [UIColor redColor];
            return;
        }
        
        if(post_topic.length == 0)
        {
            self.descriptionLabel.backgroundColor = [UIColor redColor];
            return;
        }
        
        NSNumber *severityNumber;
        if([severity isEqualToString:@"Routine"])
            severityNumber = [NSNumber numberWithInt:2];
        else
            severityNumber = [NSNumber numberWithInt:1];
        
        NSString *post_type = @"1";
        NSString *post_by = user.user_id;
        NSDate *post_date = [NSDate date];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:post_topic,@"post_topic",post_by,@"post_by",post_date,@"post_date",post_type,@"post_type",severityNumber,@"severity",@"0",@"status",location,@"address",level,@"level",postal_code,@"postal_code",blockId,@"block_id",post_date,@"updated_on",[NSNumber numberWithBool:YES],@"seen",contract_type_id,@"contract_type", nil];
        

        long long lastClientPostId =  [post savePostWithDictionary:dict];
        
        NSNumber *lastClientPostIdID = [NSNumber numberWithLongLong:lastClientPostId];
        
        if(lastClientPostId > 0)
        {
            //save image to app documents dir
            for (int i = 0; i < self.photoArrayFull.count; i++) {
                UIImage *image = [self.photoArrayFull objectAtIndex:i];
                
                NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                
                //save the image to app documents dir
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
                
                NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
                [jpegImageData writeToFile:filePath atomically:YES];
                
                NSFileManager *fManager = [[NSFileManager alloc] init];
                if([fManager fileExistsAtPath:filePath] == NO)
                    return;
                
                //resize the saved image
                [imgOpts resizeImageAtPath:filePath];
                
                //save full image to comress album
                [myDatabase saveImageToComressAlbum:image];
                
                //save images to db
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    BOOL postImageSaved;
                    
                    postImageSaved = [db executeUpdate:@"insert into post_image (client_post_id,image_path,status,downloaded,uploaded,image_type) values (?,?,?,?,?,?)",lastClientPostIdID,imageFileName,@"new",@"yes",@"no",[NSNumber numberWithInt:1]];
                    
                    if(!postImageSaved)
                    {
                        *rollback = YES;
                        DDLogVerbose(@"insert failed: %@ [%@-%@]",[db lastErrorMessage],THIS_FILE,THIS_METHOD);
                        return;
                    }
                }];
            }
            
            //save to su_feedback_issue
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                //get the contract type of this post and use it as value for issue_des
                NSString *contracTypeString;
                FMResultSet *rsGetContractStr = [db executeQuery:@"select * from contract_type where id = ?",contract_type_id];
                while ([rsGetContractStr next]) {
                    contracTypeString = [rsGetContractStr stringForColumn:@"contract"];
                }
                
                
                BOOL ins = [db executeUpdate:@"insert into su_feedback_issue (client_feedback_id,client_post_id,issue_des) values (?,?,?)",feedBackId,lastClientPostIdID,contracTypeString];
                
                if(!ins)
                {
                    *rollback = YES;
                    return ;
                }
               
            }];
            
            
            [self dismissViewControllerAnimated:YES completion:^{
               
                NSDictionary *surveyIdDict = @{@"surveyId":surveyId};
                
                if(pushFromSurveyAndModalFromFeedback)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"go_back_to_survey" object:nil userInfo:surveyIdDict];
                }
                else
                {
                    //base on wireframe
                    //[[NSNotificationCenter defaultCenter] postNotificationName:@"push_survey_detail" object:nil userInfo:surveyIdDict];
                    
                    //not base on wireframe, go back to previous vc(resident info)
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"go_back_to_survey" object:nil userInfo:surveyIdDict];
                }
            }];
        }
        
        
        if(i <= selectedContractTypesArr.count - 1) //last loop
        {
            [self dismissViewControllerAnimated:YES completion:^{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    Synchronize *sync = [Synchronize sharedManager];
                    [sync uploadSurveyFromSelf:NO];
                });
                
                NSDictionary *surveyIdDict = @{@"surveyId":surveyId};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"go_back_to_survey" object:nil userInfo:surveyIdDict];
            }];
        }
        
    }//end of for loop
}


- (void)createCrmWithDictionary:(NSDictionary *)dict
{
    NSString *postal_code = [dict valueForKey:@"postal_code"];
    NSString *location = [dict valueForKey:@"location"];
    NSString *level = [dict valueForKey:@"level"];
    NSString *post_topic = [dict valueForKey:@"post_topic"];
    NSArray *photosArray = [dict objectForKey:@"photoArray"];
    NSNumber *clientFeedbackIssueId = [dict valueForKey:@"clientFeedbackIssueId"];
    
    __block NSNumber *clientCrmId = 0;
    
    //save crm
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        BOOL insCrm = [db executeUpdate:@"insert into suv_crm(client_feed_back_issue_id,description,postal_code,address,level,no_of_image) values (?,?,?,?,?,?)",clientFeedbackIssueId,post_topic,postal_code,location,level,[NSNumber numberWithUnsignedInteger:photosArray.count]];
        
        if(!insCrm)
        {
            *rollback = YES;
            return;
        }
        else
        {
            clientCrmId = [NSNumber numberWithLong:[db lastInsertRowId]];
        }
        
    }];
    
    
    
    //save image to app documents dir
    for (int i = 0; i < photosArray.count; i++) {
        UIImage *image = [photosArray objectAtIndex:i];
        
        NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
        
        //save the image to app documents dir
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
        
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
        [jpegImageData writeToFile:filePath atomically:YES];
        
        NSFileManager *fManager = [[NSFileManager alloc] init];
        if([fManager fileExistsAtPath:filePath] == NO)
            return;
        
        //resize the saved image
        [imgOpts resizeImageAtPath:filePath];
        
        //save full image to comress album
        [myDatabase saveImageToComressAlbum:image];
        
        //save images to db
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
           
            BOOL insCrmImage = [db executeUpdate:@"insert into suv_crm_image (client_crm_id,image_path) values (?,?)",clientCrmId,imageFileName];
            
            if(!insCrmImage)
            {
                *rollback = YES;
                return;
            }
        }];
    }
}

@end
