//
//  InitializerViewController.m
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "InitializerViewController.h"
#import <math.h>

@interface InitializerViewController ()
{
 
}
@end

@implementation InitializerViewController

@synthesize imagesArr,imageDownloadComplete;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    blocks          = [[Blocks alloc] init];
    posts           = [[Post alloc] init];
    comments        = [[Comment  alloc] init];
    postImage       = [[PostImage alloc] init];
    comment_noti    = [[Comment_noti alloc] init];
    client          = [[Client alloc] init];
    questions       = [[Questions alloc] init];
    
    imagesArr = [[NSMutableArray alloc] init];
    
    imageDownloadComplete = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rouInitDone) name:@"rouInitDone" object:nil];

    [self checkBlockCount];
}

- (void)rouInitDone
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initializingCompleteWithUi:(BOOL)withUi
{
    if(withUi == NO) //init not complete
    {
        [myDatabase setInitTo:0];
    }
    else
        [myDatabase setInitTo:1];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


 #pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //go directly
    [segue destinationViewController];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - check if we need to sync blocks
- (void)checkBlockCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from blocks_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            //save block count
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from blocks"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadBlocksForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                if(myDatabase.userBlocksInitComplete == 1)
                    [self checkPostCount];
                else
                    [self checkUserBlockCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];

    }];
}

#pragma mark - check if we need to sync user blocks
- (void)checkUserBlockCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        myDatabase.userBlocksInitComplete = 0;
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from blocks_user_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_user_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"UserBlockContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            //save block count
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from blocks_user"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                    else
                        myDatabase.userBlocksInitComplete = 1;
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadBlocksUserForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                myDatabase.userBlocksInitComplete = 1;
                
                [self downloadBlockUserMappingCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            myDatabase.userBlocksInitComplete = 0;
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


#pragma mark - check if we need to sync user blocks mapping
- (void)downloadBlockUserMappingCount
{
    myDatabase.userBlocksMappingInitComplete = NO;
    
    [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_user_block_mapping] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *BlockUserMappingList = (NSArray *)[responseObject objectForKey:@"BlockUserMappingList"];

        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
           
            BOOL del = [db executeUpdate:@"delete from block_user_mapping"];
            if(!del)
            {
                *rollback = YES;
                return;
            }
            
            
            FMResultSet *rs = [db executeQuery:@"select count(*) as count from block_user_mapping"];
            BOOL downloadBlocksUserMapping = NO;
            while ([rs next]) {
                if([rs intForColumn:@"count"] == 0)
                    downloadBlocksUserMapping = YES;
            }
            
            if(downloadBlocksUserMapping == NO)
            {
                [self checkPostCount];
                return;
            }

            
            for (int i = 0 ; i < BlockUserMappingList.count; i++) {
                NSDictionary *theDict = [BlockUserMappingList objectAtIndex:i];
                
                NSNumber *BlkId = [NSNumber numberWithInt:[[theDict valueForKey:@"BlkId"] intValue]];
                NSString *SupervisorId = [[theDict valueForKey:@"SupervisorId"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *UserId = [[theDict valueForKey:@"UserId"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *division = [[theDict valueForKey:@"DivName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                BOOL ins = [db executeUpdate:@"insert into block_user_mapping(block_id, supervisor_id, user_id, division) values (?,?,?,?)",BlkId,SupervisorId,UserId,division];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
        }];
        
        myDatabase.userBlocksMappingInitComplete = YES;
        
        [self checkPostCount];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        myDatabase.userBlocksMappingInitComplete = NO;
        [self initializingCompleteWithUi:NO];
    }];
 
}


#pragma mark - check if we need to sync posts
- (void)checkPostCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownload = NO;
            
            //save block count
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from post"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownload = YES;
                    }
                }
            }];
            
            //FORCE DOWNLOAD!!!
//            if(needToDownload)
                [self startDownloadPostForPage:1 totalPage:0 requestDate:nil withUi:YES];
//            else
//                [self checkCommentCount];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
    }];
}

#pragma mark - check if we need to sync comment
- (void)checkCommentCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from comment_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownload = NO;
            
            //save block count
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsCount = [theDb executeQuery:@"select count(*) as total from comment"];
                
                while ([rsCount next]) {
                    int total = [rsCount intForColumn:@"total"];
                    if(total < totalRows)
                    {
                        needToDownload = YES;
                    }
                }
            }];
            
            if([[dict objectForKey:@"CommentList"] count] > 0)
                [self startDownloadCommentsForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
                [self checkPostImagesCount];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
    }];
}

#pragma mark - download post images
-(void)checkPostImagesCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        imgOpts = [ImageOptions new];
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from post_image_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};

        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownload = NO;
            
            
            FMResultSet *rsCount = [db executeQuery:@"select count(*) as total from post_image"];
            
            while ([rsCount next]) {
                int total = [rsCount intForColumn:@"total"];

                if(total < totalRows)
                {
                    needToDownload = YES;
                }
            }
            
            
            if(needToDownload)
                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
                [self checkCommentNotiCount];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
    }];
}

#pragma mark - check comment noti
-(void)checkCommentNotiCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from comment_noti_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};

        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownload = NO;
            
            
            FMResultSet *rsCount = [db executeQuery:@"select count(*) as total from comment_noti"];
            
            while ([rsCount next]) {
                int total = [rsCount intForColumn:@"total"];

                if(total < totalRows)
                {
                    needToDownload = YES;
                }
            }
            
            if(needToDownload)
                [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
                [self checkQuestionsCount];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
    }];
}


- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading notifications page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the comment_noti!
        NSArray *dictArray = [dict objectForKey:@"CommentNotiList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictNoti = [dictArray objectAtIndex:i];
            
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"CommentId"] intValue]];
            NSString *UserId = [dictNoti valueForKey:@"UserId"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"PostId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictNoti valueForKey:@"Status"] intValue]];

            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                theDb.traceExecution = NO;
                
                FMResultSet *rsCommentNotiCheck = [theDb executeQuery:@"select * from comment_noti where comment_id = ? and user_id = ? and post_id = ?",CommentId,UserId,PostId];
                
                if([rsCommentNotiCheck next] == NO)
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into comment_noti(comment_id, user_id, post_id, status) values(?,?,?,?)",CommentId,UserId,PostId,Status];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentNotiForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [comment_noti updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkQuestionsCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading images page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];

        [imagesArr addObject:dict];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostImagesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            [self SavePostImagesToDb];
        }
        

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}


- (void)SavePostImagesToDb
{
    
    NSDictionary *topDict = (NSDictionary *)[imagesArr lastObject];

    NSDate *lastRequestDate = [myDatabase createNSDateWithWcfDateString:[topDict valueForKey:@"LastRequestDate"]];
    
    if (imagesArr.count > 0) {

        SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
        
        for (int xx = 0; xx < imagesArr.count; xx++) {
            NSDictionary *dict = (NSDictionary *) [imagesArr objectAtIndex:xx];
            
            
            NSArray *ImageList = [dict objectForKey:@"ImageList"];
            
            for (int j = 0; j < ImageList.count; j++) {
                
                NSDictionary *ImageListDict = [ImageList objectAtIndex:j];
                
                NSNumber *CommentId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"CommentId"] intValue]];
                NSNumber *ImageType = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"ImageType"] intValue]];
                NSNumber *PostId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"PostId"] intValue]];
                NSNumber *PostImageId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"PostImageId"] intValue]];
                NSMutableString *ImagePath = [[NSMutableString alloc] initWithString:myDatabase.domain];
                NSString *imageFilename = [ImageListDict valueForKey:@"ImagePath"];
                
                if([CommentId intValue] > 1)
                {
                    [ImagePath appendString:[NSString stringWithFormat:@"ComressMImage/comment/%d/%@",[CommentId intValue],imageFilename]];
                }
                else if ([PostId intValue] > 1)
                {
                    [ImagePath appendString:[NSString stringWithFormat:@"ComressMImage/post/%d/%@",[PostId intValue],imageFilename]];
                }
                
                [sd_manager downloadImageWithURL:[NSURL URLWithString:ImagePath] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    
                    if(expectedSize > 1 && receivedSize > 1)
                    {
                        NSInteger percentage = 100 / (expectedSize / receivedSize);
                        @try {
                            //sometimes dragons appear here!
                            self.processLabel.text = [NSString stringWithFormat:@"Downloading image. %ld%%",(long)percentage];
                        }
                        @catch (NSException *exception) {
                            NSLog(@"%@-%@ %@",THIS_FILE,THIS_METHOD,exception);
                        }
                        @finally {
                            
                        }
                    }
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    
                    if(image != nil)
                    {
                        //create the image here
                        NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                        
                        //save the image to app documents dir
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsPath = [paths objectAtIndex:0];
                        
                        NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFilename]; //Add the file name
                        [jpegImageData writeToFile:filePath atomically:YES];
                        
                        NSFileManager *fManager = [[NSFileManager alloc] init];
                        if([fManager fileExistsAtPath:filePath] == NO)
                            return;
                        
                        //resize the saved image
                        [imgOpts resizeImageAtPath:filePath];
                        
                        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                            
                            FMResultSet *rsPostImage = [db executeQuery:@"select post_image_id from post_image where post_image_id = ? and (post_image_id is not null or post_image_id > ?)",PostImageId,[NSNumber numberWithInt:0]];
                            
                            if([rsPostImage next] == NO) //does not exist, insert
                            {
                                BOOL qIns = [db executeUpdate:@"insert into post_image(comment_id, image_type, post_id, post_image_id, image_path) values(?,?,?,?,?)",CommentId,ImageType,PostId,PostImageId,imageFilename];
                                
                                if(!qIns)
                                {
                                    *rollback = YES;
                                    return;
                                }
                            }
                            
                            if(imagesArr.count-1 == xx) //last image
                            {
                                FMResultSet *rs = [db executeQuery:@"select * from post_image_last_request_date"];
                                
                                if(![rs next])
                                {
                                    BOOL qIns = [db executeUpdate:@"insert into post_image_last_request_date(date) values(?)",lastRequestDate];
                                    
                                    if(!qIns)
                                    {
                                        *rollback = YES;
                                        return;
                                    }
                                }
                                else
                                {
                                    BOOL qUp = [db executeUpdate:@"update post_image_last_request_date set date = ? ",lastRequestDate];
                                    
                                    if(!qUp)
                                    {
                                        *rollback = YES;
                                        return;
                                    }
                                }
                                
                                imageDownloadComplete = YES;
                                
                                self.processLabel.text = @"Download complete";
                            }
                        }];
                        
                        if(imageDownloadComplete == YES)
                            [self checkCommentNotiCount];
                    }
                    else
                        [self checkCommentNotiCount];
                }];
            }
        }
    }
    else
    {
        [self checkCommentNotiCount];
    }
}

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading comments page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"CommentList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictComment = [dictArray objectAtIndex:i];
            
            NSString *CommentBy = [dictComment valueForKey:@"CommentBy"];
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentId"] intValue]];
            NSString *CommentString = [dictComment valueForKey:@"CommentString"];
            NSNumber *CommentType =  [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictComment valueForKey:@"PostId"] intValue]];
            NSDate *CommentDate = [myDatabase createNSDateWithWcfDateString:[dictComment valueForKey:@"CommentDate"]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsCommentCheck = [theDb executeQuery:@"select * from comment where comment_id = ?",CommentId];
                if([rsCommentCheck next] == NO)
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into comment (comment_by, comment_id, comment, comment_type, post_id, comment_on) values (?,?,?,?,?,?)",CommentBy,CommentId,CommentString,CommentType,PostId,CommentDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
            {
                NSInteger startPosition = [[dict valueForKey:@"LastRequestDate"] rangeOfString:@"("].location + 1; //start of the date value
                NSTimeInterval unixTime = [[[dict valueForKey:@"LastRequestDate"] substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    FMResultSet *rs = [theDb executeQuery:@"select * from comment_last_request_date"];
                    
                    if(![rs next])
                    {
                        BOOL qIns = [theDb executeUpdate:@"insert into comment_last_request_date(date) values(?)",date];
                        
                        if(!qIns)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    else
                    {
                        BOOL qUp = [theDb executeUpdate:@"update comment_last_request_date set date = ? ",date];
                        
                        if(!qUp)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }];
            }
            
            
            self.processLabel.text = @"Download complete";
            
            [self checkPostImagesCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading posts page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"PostList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictPost = [dictArray objectAtIndex:i];
            NSNumber *ActionStatus = [NSNumber numberWithInt:[[dictPost valueForKey:@"ActionStatus"] intValue]];
            NSString *BlkId = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"BlkId"] intValue]];
            NSString *Level = [dictPost valueForKey:@"Level"];
            NSString *Location = [dictPost valueForKey:@"Location"];
            NSString *PostBy = [dictPost valueForKey:@"PostBy"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictPost valueForKey:@"PostId"] intValue]];
            NSString *PostTopic = [dictPost valueForKey:@"PostTopic"];
            NSString *PostType = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"PostType"] intValue]];
            NSString *PostalCode = [dictPost valueForKey:@"PostalCode"];
            NSNumber *Severity = [NSNumber numberWithInt:[[dictPost valueForKey:@"Severity"] intValue]];
            NSDate *PostDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"PostDate"]];
            NSDate *DueDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"DueDate"]];
            NSDate *LastUpdatedDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"LastUpdatedDate"]];
            NSNumber *contractType = [dictPost valueForKey:@"PostGroup"];
            NSNumber *RelatedPostId = [NSNumber numberWithInt:[[dictPost valueForKey:@"RelatedPostId"] intValue]];
            NSNumber *IsNew = [NSNumber numberWithBool:[[dictPost valueForKey:@"IsNew"] boolValue]];
            
            if([IsNew boolValue] == YES)
                IsNew = [NSNumber numberWithBool:NO];
            else
                IsNew = [NSNumber numberWithBool:YES];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPostCheck = [theDb executeQuery:@"select * from post where post_id = ?",PostId];
                if([rsPostCheck next] == NO)
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date, updated_on, contract_type, dueDate, relatedPostId, seen) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate, LastUpdatedDate, contractType, DueDate, RelatedPostId,IsNew];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL ups = [theDb executeUpdate:@"update post set status = ?, block_id = ?, level = ?, address = ?, post_by = ?, post_topic = ?, post_type = ?, postal_code = ?, severity = ?, post_date = ?, contract_type = ?, dueDate = ?, updated_on = ?, seen = ?, relatedPostId = ? where post_id = ?",ActionStatus,BlkId,Level,Location,PostBy,PostTopic,PostType,PostalCode,Severity,PostDate,contractType,DueDate,LastUpdatedDate, IsNew, RelatedPostId, PostId];
                    
                    if(!ups)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [posts updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkCommentCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}

- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];


    self.processLabel.text = [NSString stringWithFormat:@"Downloading blocks page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"%@",params);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"BlockList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictBlock = [dictArray objectAtIndex:i];
            NSNumber *BlkId = [NSNumber numberWithInt:[[dictBlock valueForKey:@"BlkId"] intValue]];
            NSString *BlkNo = [dictBlock valueForKey:@"BlkNo"];
            NSNumber *IsOwnBlk = [NSNumber numberWithInt:[[dictBlock valueForKey:@"IsOwnBlk"] intValue]];
            NSString *PostalCode = [dictBlock valueForKey:@"PostalCode"];
            NSString *StreetName = [dictBlock valueForKey:@"StreetName"];
            NSNumber *lat = [dictBlock valueForKey:@"Latitude"];
            NSNumber *lon = [dictBlock valueForKey:@"Longitude"];
            
//            cos_lat = cos(lat * PI / 180)
//            sin_lat = sin(lat * PI / 180)
//            cos_lng = cos(lng * PI / 180)
//            sin_lng = sin(lng * PI / 180)
            
            
            double cos_lat = cos([[dictBlock valueForKey:@"Latitude"] doubleValue] * M_PI / 180);
            double sin_lat = sin([[dictBlock valueForKey:@"Latitude"] doubleValue] * M_PI / 180);
            double cos_lng = cos([[dictBlock valueForKey:@"Longitude"] doubleValue] * M_PI / 180);
            double sin_lng = sin([[dictBlock valueForKey:@"Longitude"] doubleValue] * M_PI / 180);
            
            NSNumber *cos_lat_val = [NSNumber numberWithDouble:cos_lat];
            NSNumber *cos_lng_val = [NSNumber numberWithDouble:cos_lng];
            NSNumber *sin_lat_val = [NSNumber numberWithDouble:sin_lat];
            NSNumber *sin_lng_val = [NSNumber numberWithDouble:sin_lng];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *blockIsExist = [theDb executeQuery:@"select block_id from blocks where block_id = ?",BlkId];
                if([blockIsExist next] == NO)
                {
                    if(lat > 0 && lon > 0)
                    {
                        BOOL qBlockIns = [theDb executeUpdate:@"insert into blocks (block_id, block_no, is_own_block, postal_code, street_name, latitude, longitude,cos_lat,cos_lng,sin_lat,sin_lng) values (?,?,?,?,?,?,?,?,?,?,?)",BlkId,BlkNo,IsOwnBlk,PostalCode,StreetName,lat,lon,cos_lat_val,cos_lng_val,sin_lat_val,sin_lng_val];
                        
                        if(!qBlockIns)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }
                else //update
                {
                    if(lat > 0 && lon > 0)
                    {
                        BOOL ups = [theDb executeUpdate:@"update blocks set block_no = ?, is_own_block = ?, postal_code = ?, street_name = ?, latitude = ?, longitude = ?, cos_lat = ?, cos_lng = ?, sin_lat = ?, sin_lng = ? where block_id = ? ",BlkNo,IsOwnBlk,PostalCode,StreetName,lat,lon,cos_lat_val,cos_lng_val,sin_lat_val,sin_lng_val,BlkId];
                        
                        if(!ups)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadBlocksForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [blocks updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"] forCurrentUser:NO];
            
            self.processLabel.text = @"Download complete";
            
            if(myDatabase.userBlocksInitComplete == 1)
                [self checkPostCount];
            else
                [self checkUserBlockCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        DDLogVerbose(@"%@",[myDatabase toJsonString:params]);
        DDLogVerbose(@"%@",[myDatabase.userDictionary valueForKey:@"guid"]);
        DDLogVerbose(@"%@",requestDate);
        DDLogVerbose(@"%@",[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_blocks]);
        [self initializingCompleteWithUi:NO];
    }];
}


- (void)startDownloadBlocksUserForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your blocks page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_user_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"UserBlockContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"UserBlockList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictBlock = [dictArray objectAtIndex:i];
            NSNumber *BlkId = [NSNumber numberWithInt:[[dictBlock valueForKey:@"BlkId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qBlockIns = [theDb executeUpdate:@"insert into blocks_user (block_id) values (?)",BlkId];
                
                if(!qBlockIns)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadBlocksUserForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [blocks updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"] forCurrentUser:YES];
            
            self.processLabel.text = @"Download complete";
            
            myDatabase.userBlocksInitComplete = 1;
            
            [self downloadBlockUserMappingCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self checkQuestionsCount];
        
        [self initializingCompleteWithUi:NO];
    }];
}


#pragma mark - check questions count
- (void)checkQuestionsCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from su_questions_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"QuestionContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from su_questions"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkSurveyCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self checkSurveyCount];

        }];
        
    }];
}

- (void)startDownloadQuestionsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your survey questions... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"QuestionContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"QuestionList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *CNQuestion = [dictList valueForKey:@"CNQuestion"];
            NSString *ENQuestion = [dictList valueForKey:@"ENQuestion"];
            NSString *INQuestion = [dictList valueForKey:@"INQuestion"];
            NSString *MYQuestion = [dictList valueForKey:@"MYQuestion"];
            NSNumber *QuestionId = [NSNumber numberWithInt:[[dictList valueForKey:@"QuestionId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rs = [theDb executeQuery:@"select question_id from su_questions where question_id = ?",QuestionId];
                
                if([rs next] == NO)//does not exist
                {
                    BOOL ins = [theDb executeUpdate:@"insert into su_questions (cn,en,my,ind,question_id) values (?,?,?,?,?)",CNQuestion,ENQuestion,MYQuestion,INQuestion,QuestionId];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadQuestionsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [questions updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkFeedBackIssuesCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self checkFeedBackIssuesCount];
    }];
}


#pragma mark - check questions count
- (void)checkFeedBackIssuesCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from su_feedback_issues_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_feedback_issues] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"FeedbackIssueContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from su_feedback_issue"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkSurveyCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self checkSurveyCount];
        }];
        
    }];
}


#pragma mark - download new data from server
- (void)startDownloadFeedBackIssuesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your survey... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_feedback_issues] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"FeedbackIssueContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"FeedbackIssueList"];
        
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictPost = [dictArray objectAtIndex:i];
            
            NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[dictPost valueForKey:@"FeedbackIssueId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictPost valueForKey:@"Status"] intValue]];
            NSDate *LastUpdatedDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"LastUpdatedDate"]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select feedback_issue_id from su_feedback_issue where feedback_issue_id = ?",FeedbackIssueId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into su_feedback_issue (feedback_issue_id,status,updated_on) values (?,?,?)",FeedbackIssueId,Status,LastUpdatedDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL ups = [theDb executeUpdate:@"update su_feedback_issue set feedback_issue_id = ?, status = ?, updated_on = ? where feedback_issue_id = ? ",FeedbackIssueId,Status,LastUpdatedDate,FeedbackIssueId];
                    
                    if(!ups)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadFeedBackIssuesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:YES];
        }
        else
        {
            if(dictArray.count > 0)
            {
                //update last request date
                NSString *dateString = [dict valueForKey:@"LastRequestDate"];
                NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
                NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    FMResultSet *rs = [theDb executeQuery:@"select * from su_feedback_issues_last_req_date"];
                    
                    if(![rs next])
                    {
                        BOOL qIns = [theDb executeUpdate:@"insert into su_feedback_issues_last_req_date(date) values(?)",date];
                        
                        if(!qIns)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    else
                    {
                        BOOL qUp = [theDb executeUpdate:@"update su_feedback_issues_last_req_date set date = ? ",date];
                        
                        if(!qUp)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }];
                
                self.processLabel.text = @"Download complete";
                
            }
            
            [self checkSurveyCount];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self checkSurveyCount];
    }];
}


- (void)checkSurveyCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from su_survey_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_survey] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ResturnSurveyContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from su_survey"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            NSArray *surveyListArr = [dict objectForKey:@"SurveyList"];
            if(surveyListArr.count > 0)
            {
                NSRange range = [[myDatabase.userDictionary valueForKey:@"group_name"] rangeOfString:@"CT"];
                
                if(range.location == NSNotFound) //current user does not belong to contractor group
                    [self startDownloadSurveyPage:1 totalPage:0 requestDate:nil withUi:YES];
                else
                    [self startDownloadContractTypePage:1 totalPage:0 requestDate:nil withUi:YES];
            }
            else
                [self startDownloadContractTypePage:1 totalPage:0 requestDate:nil withUi:YES];
            

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:YES];
        }];
        
    }];
}

#pragma mark - download survey
- (void)startDownloadSurveyPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your survey... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_survey] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        NSDictionary *dict = [responseObject objectForKey:@"ResturnSurveyContainer"];
        
        //save address
        NSArray *AddressList = [dict objectForKey:@"AddressList"];
        for (int i = 0; i < AddressList.count; i++) {
            NSNumber *AddressId = [NSNumber numberWithInt:[[[AddressList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
            NSNumber *Location = [[AddressList objectAtIndex:i] valueForKey:@"Location"];
            NSString *SpecifyArea = [[AddressList objectAtIndex:i] valueForKey:@"SpecifyArea"];
            NSString *UnitNo = [[AddressList objectAtIndex:i] valueForKey:@"UnitNo"];
            NSString *PostalCode = [[AddressList objectAtIndex:i] valueForKey:@"PostalCode"];
            NSNumber *BlkId = [NSNumber numberWithInt:[[[AddressList objectAtIndex:i] valueForKey:@"BlkId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_address where address_id = ?",AddressId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_address(address_id,address,unit_no,specify_area,postal_code,block_id) values (?,?,?,?,?,?)",AddressId,Location,UnitNo,SpecifyArea,PostalCode,BlkId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save answers
        NSArray *AnswerList = [dict objectForKey:@"AnswerList"];
        for (int i = 0; i < AnswerList.count; i++) {
            NSNumber *AnswerId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"AnswerId"] intValue]];
            NSNumber *QuestionId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"QuestionId"] intValue]];
            NSNumber *Rating = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"Rating"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_answers where answer_id = ?",AnswerId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_answers(answer_id,question_id,rating,survey_id) values (?,?,?,?)",AnswerId,QuestionId,Rating,SurveyId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save FeedbackIssueList
        NSArray *FeedbackIssueList = [dict objectForKey:@"FeedbackIssueList"];
        for (int i = 0; i < FeedbackIssueList.count; i++) {
            
            NSNumber *FeedbackId = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
            NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackIssueId"] intValue]];
            NSString *IssueDes = [[FeedbackIssueList objectAtIndex:i] valueForKey:@"IssueDes"];
            
            NSNumber *AutoAssignMe = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"AutoAssignMe"] boolValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"PostId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"Status"] intValue]];
            NSDate *LastUpdatedDate = [myDatabase createNSDateWithWcfDateString:[[FeedbackIssueList objectAtIndex:i] valueForKey:@"LastUpdatedDate"]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                db.traceExecution = NO;
                
                FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where feedback_issue_id = ?",FeedbackIssueId];

                if([rsCheckFi next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_feedback_issue(feedback_id,feedback_issue_id,issue_des,auto_assignme,post_id,status, updated_on) values (?,?,?,?,?,?,?)",FeedbackId,FeedbackIssueId,IssueDes,AutoAssignMe,PostId,Status,LastUpdatedDate];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL insUp = [db executeUpdate:@"update su_feedback_issue set feedback_id = ?, feedback_issue_id = ?, issue_des = ?, auto_assignme = ?, post_id = ?, status = ?, updated_on = ? where feedback_issue_id = ?",FeedbackId,FeedbackIssueId,IssueDes,AutoAssignMe,PostId,Status,LastUpdatedDate, FeedbackIssueId];
                    if(!insUp)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save FeedbackList
        NSArray *FeedbackList = [dict objectForKey:@"FeedbackList"];
        for (int i = 0; i < FeedbackList.count; i++) {
            
            NSNumber *AddressId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
            NSString *Description = [[FeedbackList objectAtIndex:i] valueForKey:@"Description"];
            NSNumber *FeedbackId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];
            
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_feedback where feedback_id = ?",FeedbackId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_feedback(address_id,description,feedback_id,survey_id) values (?,?,?,?)",AddressId,Description,FeedbackId,SurveyId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        
        //save Survey
        NSArray *SurveyList = [dict objectForKey:@"SurveyList"];
        for (int i = 0; i < SurveyList.count; i++) {
            
            NSNumber *AverageRating = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"AverageRating"] floatValue]];
            NSNumber *ResidentAddressId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"ResidentAddressId"] intValue]];
            NSString *ResidentAgeRange = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentAgeRange"];
            NSString *ResidentGender = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentGender"];
            NSString *ResidentName = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentName"];
            NSString *ResidentContact = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentContact"];
            NSString *Resident2ndContact  = [[SurveyList objectAtIndex:i] valueForKey:@"Resident2ndContact"];
            NSString *ResidentEmail = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentEmail"];
            NSString *ResidentRace = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentRace"];
            NSNumber *SurveyAddressId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"SurveyAddressId"] intValue]];
            NSDate *SurveyDate = [myDatabase createNSDateWithWcfDateString:[[SurveyList objectAtIndex:i] valueForKey:@"SurveyDate"]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];
            NSNumber *DataProtection = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"DataProtection"] intValue]];
            NSString *CreatedBy = [[SurveyList objectAtIndex:i] valueForKey:@"CreatedBy"];
            NSNumber *IsMine = [NSNumber numberWithBool:[[[SurveyList objectAtIndex:i] valueForKey:@"IsMine"] boolValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_survey where survey_id = ?",SurveyId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_survey(average_rating,resident_address_id,resident_age_range,resident_gender,resident_name,resident_race,survey_address_id,survey_date,survey_id,resident_contact,resident_email,data_protection, other_contact, created_by, isMine) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",AverageRating,ResidentAddressId,ResidentAgeRange,ResidentGender,ResidentName,ResidentRace,SurveyAddressId,SurveyDate,SurveyId,ResidentContact,ResidentEmail,DataProtection, Resident2ndContact, CreatedBy, IsMine];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL upSur = [db executeUpdate:@"update su_survey set average_rating = ?, resident_address_id = ?, resident_age_range = ?, resident_gender = ?, resident_name = ?, resident_race = ?, survey_address_id = ?, survey_date = ?, resident_contact = ?, resident_email = ?, data_protection = ?,  other_contact = ?,  created_by = ?,  isMine = ?where survey_id = ?",AverageRating,ResidentAddressId,ResidentAgeRange,ResidentGender,ResidentName,ResidentRace,SurveyAddressId,SurveyDate,ResidentContact,ResidentEmail,DataProtection,Resident2ndContact,CreatedBy,IsMine,SurveyId];
                    if(!upSur)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSurveyPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:YES];
        }
        else
        {
            
            //update last request date
            NSString *dateString = [dict valueForKey:@"LastRequestDate"];
            NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
            NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rs = [theDb executeQuery:@"select * from su_survey_last_req_date"];
                
                if(![rs next])
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into su_survey_last_req_date(date) values(?)",date];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL qUp = [theDb executeUpdate:@"update su_survey_last_req_date set date = ? ",date];
                    
                    if(!qUp)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
            
            [self startDownloadContractTypePage:1 totalPage:0 requestDate:nil withUi:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    
        [self initializingCompleteWithUi:NO];
    }];
}


- (void)startDownloadContractTypePage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your contract types... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_contract_types] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ContractTypeContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ContractTypeList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            
            if(i == 0)
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL del = [db executeUpdate:@"delete from contract_type"];
                    if(!del)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
            
            NSDictionary *dictList = [dictArray objectAtIndex:i];

            NSNumber *ContractTypeId = [dictList valueForKey:@"ContractTypeId"];
            NSString *ContractTypeName = [dictList valueForKey:@"ContractTypeName"];
            NSNumber *IsOutsideAllowed = [NSNumber numberWithBool:[[dictList valueForKey:@"IsOutsideAllowed"] boolValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {

                BOOL ins = [theDb executeUpdate:@"insert into contract_type(id, contract, isAllowedOutside) values (?,?,?)",ContractTypeId,ContractTypeName, IsOutsideAllowed];

                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadContractTypePage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {

            self.processLabel.text = @"Download complete";
            
            [self startDownloadPublicContractTypePage:1 totalPage:0 requestDate:nil withUi:YES];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self startDownloadPublicContractTypePage:1 totalPage:0 requestDate:nil withUi:YES];
    }];
}


- (void)startDownloadPublicContractTypePage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
    jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading your contract types... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_public_contract_types] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ContractTypeContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ContractTypeList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            
            if(i == 0)
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL del = [db executeUpdate:@"delete from contract_type_public"];
                    if(!del)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
            
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            
            NSNumber *ContractTypeId = [dictList valueForKey:@"ContractTypeId"];
            NSString *ContractTypeName = [dictList valueForKey:@"ContractTypeName"];
            NSNumber *IsOutsideAllowed = [NSNumber numberWithBool:[[dictList valueForKey:@"IsOutsideAllowed"] boolValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                BOOL ins = [theDb executeUpdate:@"insert into contract_type_public(id, contract, isAllowedOutside) values (?,?,?)",ContractTypeId,ContractTypeName, IsOutsideAllowed];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPublicContractTypePage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            
            self.processLabel.text = @"Download complete";
            
            [self initializingCompleteWithUi:YES];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}





@end
