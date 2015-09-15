//
//  RoutineChatViewController.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineChatViewController.h"

@interface RoutineChatViewController ()

@end

@implementation RoutineChatViewController

@synthesize blockId,blockNo,postDict,commentsArray,ServerPostId,postId,isFiltered;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //save this routine as a post with type = 2
    user = [[Users alloc] init];
    comment = [[Comment alloc] init];
    post = [[Post alloc] init];
    blocks = [[Blocks alloc] init];
    myDatabase = [Database sharedMyDbManager];

    NSDictionary *blockInfo = [[blocks fetchBlocksWithBlockId:blockId] lastObject];
    NSDate *post_date = [NSDate date];
    NSNumber *post_type = [NSNumber numberWithInt:2];
    NSNumber *severityNumber = [NSNumber numberWithInt:2];
    NSString *location = [NSString stringWithFormat:@"%@ %@",[blockInfo valueForKey:@"block_no"],[blockInfo valueForKey:@"street_name"]];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[blockInfo valueForKey:@"block_no"],@"post_topic",[myDatabase.userDictionary valueForKey:@"user_id"],@"post_by",post_date,@"post_date",post_type,@"post_type",severityNumber,@"severity",@"0",@"status",location,@"address",@"na",@"level",[blockInfo valueForKey:@"postal_code"],@"postal_code",blockId,@"block_id",post_date,@"updated_on",[NSNumber numberWithBool:YES],@"seen", nil];
    
    long long postIdNew = [post savePostWithDictionary:dict forBlockId:blockId];
    
    if(postIdNew > 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Synchronize *sync = [Synchronize sharedManager];
            [sync uploadPostFromSelf:NO];
        });
    }
    else
        DDLogVerbose(@"post already exist");
    
    
    
    //jsq settings
    //set sender Id
    self.senderId = user.user_id;
    self.senderDisplayName = user.full_name;
    
    //alloc our message data
    self.messageData = [[MessageDataRoutine alloc] init];
    
    self.messageData.messages = [[NSMutableArray alloc] init];
    self.showLoadEarlierMessagesHeader = YES;
    
    //update post as seen
    //get the clientPostId and ServerPostId of this routine
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select client_post_id, post_id from post where block_id = ? and post_type = ?",blockId,[NSNumber numberWithInt:2]];
        
        while ([rs next]) {
            postId = [rs intForColumn:@"client_post_id"];
            ServerPostId = [rs intForColumn:@"post_id"];
        }
    }];
    
    [post updatePostAsSeen:[NSNumber numberWithInt:postId] serverPostId:[NSNumber numberWithInt:ServerPostId]];
    
    [self fetchComments];
    
    //init location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = 100;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchComments) name:@"reloadChatView" object:nil];
}

- (void)fetchComments
{
    if(!self.isViewLoaded || !self.view.window) //only reload the list if this VC is active
        return;
     
    //clear messages
    [self.messageData.messages removeAllObjects];
    postDict = nil;
    commentsArray = nil;
    
    NSDictionary *params = @{@"order":@"order by updated_on asc"};

    if(isFiltered)
        postDict = [[post fetchIssuesWithParams:params forPostId:[NSNumber numberWithInt:self.postId] filterByBlock:YES newIssuesFirst:NO onlyOverDue:NO fromSurvey:NO] objectAtIndex:0];
    else
        postDict = [[post fetchIssuesWithParams:params forPostId:[NSNumber numberWithInt:self.postId] filterByBlock:NO newIssuesFirst:NO onlyOverDue:NO fromSurvey:NO] objectAtIndex:0];

    //get the post information so we can do a pop-up view for post
    self.postInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[[postDict objectForKey:[NSNumber numberWithInt:self.postId]] objectForKey:@"post"],@"post",[[postDict objectForKey:[NSNumber numberWithInt:self.postId]] objectForKey:@"postImages"],@"images", nil];
    
    commentsArray = [[postDict objectForKey:[NSNumber numberWithInt:self.postId]] objectForKey:@"postComments"];
    
    for (int i = 0; i < commentsArray.count; i++) {
        NSDictionary *dict = [commentsArray objectAtIndex:i];
        
        double timeStamp = [[dict valueForKeyPath:@"comment_on"] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
        
        NSString *commentString = [dict valueForKey:@"comment"];
        
        if([commentString isEqualToString:@"<image>"])
        {
            NSString *imagePath = [dict valueForKey:@"image"];
            if(imagePath != nil)
            {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
                UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                
                [self.messageData addPhotoMediaMessageWithImage:image SenderId:[dict valueForKey:@"comment_by"] DisplayName:[dict valueForKey:@"comment_by"]];
            }
        }
        else
        {
            if([[dict valueForKey:@"comment_type"] intValue] == 1) //normal text comment
            {
                JSQMessage *message = [[JSQMessage alloc] initWithSenderId:[dict valueForKey:@"comment_by"] senderDisplayName:[dict valueForKey:@"comment_by"] date:date text:commentString];
                
                [self.messageData.messages addObject:message];
            }
            else if ([[dict valueForKey:@"comment_type"] intValue] == 2) //issue status update
            {
                NSString *dateStringForm = [date stringWithHumanizedTimeDifference:0 withFullString:NO];
                
                NSString *statusComment = [NSString stringWithFormat:@"%@ (%@)",commentString,dateStringForm];
                
                JSQMessage *message = [[JSQMessage alloc] initWithSenderId:[dict valueForKey:@"comment_by"] senderDisplayName:[dict valueForKey:@"comment_by"] date:date text:statusComment];
                
                [self.messageData.messages addObject:message];
            }
        }
    }
    
    if(commentsArray.count > 0)
        [self displayMessages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:blockNo];
    [navigationBarTitleView setDetailText:@"Tap here for info."];
    
    //add tap gestuer to the navbar for the pop-over post info
    UITapGestureRecognizer *tapNavBar = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popSkedInformation)];
    tapNavBar.numberOfTapsRequired = 1;
    
    [navigationBarTitleView addGestureRecognizer:tapNavBar];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //auth pop-up sometimes crashes the app overlapping table datasource
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //ask permission to use location service
        [locationManager requestAlwaysAuthorization];
        [locationManager requestWhenInUseAuthorization];
    });
}

- (void)popSkedInformation
{
    if([[myDatabase.userDictionary valueForKey:@"contract_type"] intValue] != 4)
    {
        CheckListViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckListViewController"];
        cvc.blockId = blockId;
        
        popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:cvc];
        popover.arrowDirection = FPPopoverArrowDirectionUp;
        popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.99, CGRectGetHeight(self.view.frame) * 0.99);
        
        [popover presentPopoverFromView:self.navigationController.navigationBar];
    }
    else
    {
        CheckAreaViewController *cavc = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckAreaViewController"];
        cavc.blockId = blockId;

        UINavigationController *ncavc = [[UINavigationController alloc] initWithRootViewController:cavc];
        
        popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:ncavc];
        popover.arrowDirection = FPPopoverArrowDirectionUp;
        popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.99, CGRectGetHeight(self.view.frame) * 0.99);
        popover.title = nil;
        [popover presentPopoverFromView:self.navigationController.navigationBar];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_view_image"])
    {
        
        ImagePreviewViewController *imagePrev = [segue destinationViewController];
        JSQMessage *message = (JSQMessage *)sender;
        
        id<JSQMessageMediaData> mediaData = message.media;
        
        if ([mediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
            JSQPhotoMediaItem *photoItem = [((JSQPhotoMediaItem *)mediaData) copy];
            photoItem.appliesMediaViewMaskAsOutgoing = NO;
            imagePrev.image = [UIImage imageWithCGImage:photoItem.image.CGImage];
        }
    }
}

- (IBAction)action:(id)sender
{
    DDLogVerbose(@"action");
}

#pragma mark - share media
- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose Existing Photo",@"Share Location", nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    switch (buttonIndex) {
        case 1:
        {
            [self openMediaByType:2];
            break;
        }
            
        case 2:
        {
            [self shareLocation];
            break;
        }
            
        default:
        {
            [self openMediaByType:1];
            break;
        }
    }
}

#pragma mark - share location
- (void)shareLocation
{
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Capturing location...";
    
    CLLocation *loc = [locations lastObject];
    
    CGFloat longitude = loc.coordinate.longitude;
    CGFloat latitude = loc.coordinate.latitude;
    
    NSURL *mapImageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/staticmap?center=%f,%f&zoom=16&size=750x1334&markers=color:red%%7C%f,%f",latitude,longitude,latitude,longitude]];
    
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
        [self sendLocationAsMessageWithUrl:mapImageUrl];
        [locationManager stopUpdatingLocation];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

- (void)sendLocationAsMessageWithUrl:(NSURL *)url
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    [manager downloadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        
        [self.messageData addPhotoMediaMessageWithImage:image SenderId:user.user_id DisplayName:user.user_id];
        
        //save comment
        NSDate *date = [NSDate date];
        
        NSDictionary *dict = @{@"client_post_id":[NSNumber numberWithInt:self.postId], @"text":[NSNull null],@"senderId":user.user_id,@"date":date,@"messageType":@"image",@"comment_type":[NSNumber numberWithInt:1],@"image":image};
        
        [self saveCommentForMessage:dict];
        
        [self finishReceivingMessageAnimated:YES];
    }];
}

#pragma mark - ImagePicker
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
    
    [self.messageData addPhotoMediaMessageWithImage:thumbImage SenderId:user.user_id DisplayName:user.user_id];
    
    
    //save comment
    NSDate *date = [NSDate date];
    
    NSDictionary *dict = @{@"client_post_id":[NSNumber numberWithInt:self.postId], @"text":[NSNull null],@"senderId":user.user_id,@"date":date,@"messageType":@"image",@"comment_type":[NSNumber numberWithInt:1],@"image":img};
    
    [self saveCommentForMessage:dict];
    
    [self finishReceivingMessageAnimated:YES];
    
}

#pragma mark - send message
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    NSDictionary *dict = @{@"client_post_id":[NSNumber numberWithInt:self.postId], @"text":text,@"senderId":senderId,@"date":date,@"messageType":@"text",@"comment_type":[NSNumber numberWithInt:1]};
    
    [self saveCommentForMessage:dict];
    
    [self finishSendingMessageAnimated:YES];
}

#pragma mark - save comment
- (void)saveCommentForMessage:(NSDictionary *)msg
{
    BOOL saveComment =  [comment saveCommentWithDict:msg];
    
    if(!saveComment)
        DDLogVerbose(@"comment not saved");
    
    [self fetchComments];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Synchronize *sync = [Synchronize sharedManager];
        [sync uploadCommentFromSelf:NO];
    });
    
    NSDate *rightNow = [NSDate date];
    //update post
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL upPostDateOn = [db executeUpdate:@"update post set updated_on = ? where client_post_id = ?",rightNow,[NSNumber numberWithInt:postId]];
        
        if(!upPostDateOn)
        {
            *rollback = YES;
            return;
        }
    }];
}

- (void)messageReceived
{
    JSQMessage *theMessage = [[JSQMessage alloc]initWithSenderId:user.user_id senderDisplayName:user.full_name date:[NSDate date] text:@"wooo"];
    
    [self.messageData.messages addObject:theMessage];
    
    [self displayMessages];
}

- (void)displayMessages
{
    [self scrollToBottomAnimated:YES];
    
    JSQMessage *message = [self.messageData.messages lastObject];
    
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        JSQMessage *newMessage = nil;
        id<JSQMessageMediaData> newMediaData = nil;
        id newMediaAttachmentCopy = nil;
        
        if (message.isMediaMessage) {
            /**
             *  Last message was a media message
             */
            id<JSQMessageMediaData> mediaData = message.media;
            
            if ([mediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                JSQPhotoMediaItem *photoItemCopy = [((JSQPhotoMediaItem *)mediaData) copy];
                photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItemCopy.image.CGImage];
                
                /**
                 *  Set image to nil to simulate "downloading" the image
                 *  and show the placeholder view
                 */
                photoItemCopy.image = nil;
                
                newMediaData = photoItemCopy;
            }
            else if ([mediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *locationItemCopy = [((JSQLocationMediaItem *)mediaData) copy];
                locationItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [locationItemCopy.location copy];
                
                /**
                 *  Set location to nil to simulate "downloading" the location data
                 */
                locationItemCopy.location = nil;
                
                newMediaData = locationItemCopy;
            }
            else if ([mediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)mediaData) copy];
                videoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [videoItemCopy.fileURL copy];
                
                /**
                 *  Reset video item to simulate "downloading" the video
                 */
                videoItemCopy.fileURL = nil;
                videoItemCopy.isReadyToPlay = NO;
                
                newMediaData = videoItemCopy;
            }
            else {
                DDLogVerbose(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
            }
            
            newMessage = [JSQMessage messageWithSenderId:user.user_id
                                             displayName:user.full_name
                                                   media:newMediaData];
        }
        else {
            /**
             *  Last message was a text message
             */
            newMessage = [JSQMessage messageWithSenderId:user.user_id
                                             displayName:user.full_name
                                                    text:message.text];
        }
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        
        
        [self finishReceivingMessage];
        
        
        if (newMessage.isMediaMessage) {
            /**
             *  Simulate "downloading" media
             */
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Media is "finished downloading", re-display visible cells
                 *
                 *  If media cell is not visible, the next time it is dequeued the view controller will display its new attachment data
                 *
                 *  Reload the specific item, or simply call `reloadData`
                 */
                
                if ([newMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                    ((JSQPhotoMediaItem *)newMediaData).image = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                    [((JSQLocationMediaItem *)newMediaData)setLocation:newMediaAttachmentCopy withCompletionHandler:^{
                        [self.collectionView reloadData];
                    }];
                }
                else if ([newMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                    ((JSQVideoMediaItem *)newMediaData).fileURL = newMediaAttachmentCopy;
                    ((JSQVideoMediaItem *)newMediaData).isReadyToPlay = YES;
                    [self.collectionView reloadData];
                }
                else {
                    DDLogVerbose(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
                }
                
            });
        }
        
    });
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messageData.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.messageData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.messageData.outgoingBubbleImageData;
    }
    
    return self.messageData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.messageData.messages objectAtIndex:indexPath.item];
    
    /*if ([message.senderId isEqualToString:self.senderId]) {
     if (![NSUserDefaults outgoingAvatarSetting]) {
     return nil;
     }
     }
     else {
     if (![NSUserDefaults incomingAvatarSetting]) {
     return nil;
     }
     }*/
    
    
    return [self.messageData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.messageData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messageData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messageData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.messageData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    //check if the message is action type. if so, change the font to bold and background to dark green
    
    NSDictionary *dict = [commentsArray objectAtIndex:indexPath.row];
    if([[dict valueForKey:@"comment_type"] intValue] == 2)
    {
        cell.messageBubbleImageView.image = [UIImage imageNamed:@"status_bubble"];
        UIFont* boldFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
        
        cell.textView.font = boldFont; // !experimental and not recommended
    }
    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.messageData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    DDLogVerbose(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    DDLogVerbose(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    DDLogVerbose(@"Tapped message bubble!");
    
    JSQMessage *message = [self.messageData.messages objectAtIndex:indexPath.row];
    
    if(message.media != nil)
    {
        [self performSegueWithIdentifier:@"push_view_image" sender:message];
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    DDLogVerbose(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

@end
