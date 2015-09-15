//
//  NewIssueViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "NewIssueViewController.h"
#import "Synchronize.h"

@interface NewIssueViewController ()
{
    int selectedContractTypeId;
}

@property (nonatomic, strong) NSMutableArray *photoArray;
@property (nonatomic, strong) NSMutableArray *photoArrayFull;
@property (nonatomic, strong) NSArray *severtiyArray;
@property (nonatomic, strong) NSMutableArray *contractsArray;
@property (nonatomic, strong) NSMutableArray *blocksArray;
@property (nonatomic, strong) NSMutableArray *addressArray;

@end

@implementation NewIssueViewController

@synthesize scrollView,imagePicker,blockId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    contract_type = [[Contract_type alloc] init];
    
    self.photoArray = [[NSMutableArray alloc] init];
    self.photoArrayFull = [[NSMutableArray alloc] init];
    
    self.severtiyArray = [NSArray arrayWithObjects:@"Routine",@"Severe", nil];
    
    self.contractsArray = [[NSMutableArray alloc] initWithArray:[contract_type contractTypes]];
    
    blocks = [[Blocks alloc] init];
    
    
    //watch when keyboard is up/down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //keyboard can be dimiss by scrollview event
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    //set the severity by default to Routine
    [self.severityBtn setTitle:[NSString stringWithFormat:@" %@",[self.severtiyArray objectAtIndex:0]] forState:UIControlStateNormal];
    
    //set default contract type to first object
    [self.contractTypeBtn setTitle:[NSString stringWithFormat:@" %@",[[self.contractsArray firstObject] valueForKey:@"contract"]] forState:UIControlStateNormal];
    selectedContractTypeId = [[[self.contractsArray firstObject] valueForKey:@"id"] intValue];
    
    //add border to the textview
    [[self.descriptionTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.descriptionTextView layer] setBorderWidth:1];
    [[self.descriptionTextView layer] setCornerRadius:15];
    
    blocks = [[Blocks alloc] init];
    
    [self generateData];
    
    //for autocomplete
    [self.postalCodeTextField setDelegate:self];
    [self.addressTextField setDelegate:self];
}

- (void)generateData
{
    self.blocksArray = [[NSMutableArray alloc] init];
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];

    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *postal_code = [NSString stringWithFormat:@"%@ - %@ - %@",[obj valueForKey:@"postal_code"],[obj valueForKey:@"street_name"],[obj valueForKey:@"block_no"]];
            NSString *block_no = [obj valueForKey:@"block_no"];
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@ - %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"postal_code"],[obj valueForKey:@"block_no"]];

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
    
    if([[[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"] isEqualToString:@"0"])
        self.postalCodeTextField.text = @"Not applicable";
    
    self.addressTextField.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
    
    blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
    
    //check if this blockId belongs to the current user, if not, only return the the contract type with isAllowedOutside = YES
    __block BOOL blockExists = YES;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select block_id from block_user_mapping where block_id = ?",blockId];
        
        if([rs next] == NO) //does not exist
        {
            FMResultSet *rsContracts = [db executeQuery:@"select * from contract_type where isAllowedOutside = ?",[NSNumber numberWithBool:YES]];
            
            [self.contractsArray removeAllObjects];
            while ([rsContracts next]) {
                [self.contractsArray addObject:[rsContracts resultDictionary]];
            }
            
            blockExists = NO;
        }
        else
            blockExists = YES;
    }];

    if(blockExists) //reset to default contract type list
        self.contractsArray = [[NSMutableArray alloc] initWithArray:[contract_type contractTypes]];

    
    //set default contract type to first object
    [self.contractTypeBtn setTitle:[NSString stringWithFormat:@" %@",[[self.contractsArray firstObject] valueForKey:@"contract"]] forState:UIControlStateNormal];
    selectedContractTypeId = [[[self.contractsArray firstObject] valueForKey:@"id"] intValue];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //pre-increase the contentsize of the scrollview to fit screen
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), self.scrollView.contentSize.height + 50);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)selectContractType:(id)sender
{
    [self hideKeyboard:sender];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Contract type" rows:[self.contractsArray valueForKey:@"contract"] initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {

        [self.contractTypeBtn setTitle:[NSString stringWithFormat:@" %@",[[self.contractsArray objectAtIndex:selectedIndex] valueForKey:@"contract"]] forState:UIControlStateNormal];
        selectedContractTypeId = [[[self.contractsArray objectAtIndex:selectedIndex] valueForKey:@"id"] intValue];
        
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
    user = [[Users alloc] init];
    post = [[Post alloc] init];
    postImage = [[PostImage alloc] init];
    
    NSString *postal_code = [self.postalCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *location = [self.addressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *level = [self.levelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *post_topic = [self.descriptionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *severity = [self.severityBtn.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSNumber *contract_type_id = [NSNumber numberWithInt:selectedContractTypeId];
    
    if([contract_type_id intValue] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"COMRESS" message:@"Please select a valid contract type" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
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
            
            //save the image info to local db
            NSNumber *lastClientPostIdID = [NSNumber numberWithLongLong:lastClientPostId];
            
            //save full image to comress album
            [myDatabase saveImageToComressAlbum:image];
            
            //save images to db
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                BOOL postImageSaved;
                
                postImageSaved = [db executeUpdate:@"insert into post_image (client_post_id,image_path,status,downloaded,uploaded,image_type) values (?,?,?,?,?,?)",lastClientPostIdID,imageFileName,@"new",@"yes",@"no",[NSNumber numberWithInt:1]];
                
                if(!postImageSaved)
                {
                    *rollback = YES;

                    return;
                }
            }];
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            //get the saved post and pass it a notification to auto-open the chat view
            
            NSDictionary *useInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:lastClientPostId] forKey:@"lastClientPostId"];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rs = [db executeQuery:@"select block_id from blocks_user where block_id = ?",blockId];
                
                if([rs next])
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"autoOpenChatViewForPostMe" object:nil userInfo:useInfo];
                else
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"autoOpenChatViewForPostOthers" object:nil userInfo:useInfo];

            }];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Synchronize *sync = [Synchronize sharedManager];
                [sync uploadPostFromSelf:NO];
            });
        }];
    }
    
    [Answers logCustomEventWithName:@"Created Issue" customAttributes:myDatabase.userDictionary];
}

@end
