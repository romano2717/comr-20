//

//  Synchronize.m
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Synchronize.h"

@implementation Synchronize

@synthesize syncKickstartTimerOutgoing,syncKickstartTimerIncoming,imagesArr,imageDownloadComplete,downloadIsTriggeredBySelf,stop;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        imagesArr = [[NSMutableArray alloc] init];
        
        //sync flags
        self.uploadPostFromSelfIsFinished = YES;
        self.uploadCommentFromSelfIsFinished = YES;
        self.uploadPostStatusChangeFromSelfIsFinished = YES;
        self.uploadCommentNotiAlreadyReadFromSelfIsFinished = YES;
        self.uploadImageFromSelfIsFinished = YES;
        self.uploadInspectionResultFromSelfIsFinished = YES;
        self.uploadSurveyFromSelfIsFinished = YES;
        self.uploadCrmFromSelfIsFinished = YES;
        self.uploadCrmImageFromSelfIsFinished = YES;
        self.uploadReassignPostFromSelfIsFinished = YES;
    }
    return self;
}

+(id)sharedManager {
    static Synchronize *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)kickStartSync
{
    stop = NO;
    
    //outgoing
    //[self uploadPostFromSelf:YES];
    syncKickstartTimerOutgoing = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(uploadPost) userInfo:nil repeats:YES];

//    [self startDownload];
//    downloadIsTriggeredBySelf = YES;
//    syncKickstartTimerIncoming = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(startDownload) userInfo:nil repeats:YES];
}


- (void)uploadPost
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    [self uploadPostFromSelf:YES];
}


- (void)startDownload
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if([syncKickstartTimerIncoming isValid])
        [syncKickstartTimerIncoming invalidate]; //init is done, no need for timer. post, comment, image, etc will recurse automatically.
    
    //incoming
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //__block NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
        

        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download post
            FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
            
            if([rs next])
            {
                jsonDate = (NSDate *)[rs dateForColumn:@"date"];
                
            }
            [self startDownloadPostForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download post image
            FMResultSet *rs2 = [db executeQuery:@"select date from post_image_last_request_date"];
            
            if([rs2 next])
            {
                jsonDate = (NSDate *)[rs2 dateForColumn:@"date"];
                
            }
            [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download comments
            FMResultSet *rs3 = [db executeQuery:@"select date from comment_last_request_date"];
            
            if([rs3 next])
            {
                jsonDate = (NSDate *)[rs3 dateForColumn:@"date"];
            }
            [self startDownloadCommentsForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download comment noti
            FMResultSet *rs4 = [db executeQuery:@"select date from comment_noti_last_request_date"];
            
            if([rs4 next])
            {
                jsonDate = (NSDate *)[rs4 dateForColumn:@"date"];
            }
            [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download questions
            FMResultSet *rs55 = [db executeQuery:@"select date from su_questions_last_req_date"];
            
            if([rs55 next])
            {
                jsonDate = (NSDate *)[rs55 dateForColumn:@"date"];
            }
            [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download survey
            FMResultSet *rs5 = [db executeQuery:@"select date from su_survey_last_req_date"];
            
            if([rs5 next])
            {
                jsonDate = (NSDate *)[rs5 dateForColumn:@"date"];
            }
            [self startDownloadSurveyPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download feedback issues list
            FMResultSet *rs6 = [db executeQuery:@"select date from su_feedback_issues_last_req_date"];
            
            if([rs6 next])
            {
                jsonDate = (NSDate *)[rs6 dateForColumn:@"date"];
            }
            [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:jsonDate];
            
            
//            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
//            //download blocks list
//            FMResultSet *rs7 = [db executeQuery:@"select date from blocks_last_request_date"];
//            
//            if([rs7 next])
//            {
//                jsonDate = (NSDate *)[rs7 dateForColumn:@"date"];
//            }
//            [self startDownloadBlocksForPage:1 totalPage:0 requestDate:jsonDate];
        }];
    });
}

#pragma mark - upload new data to server

- (void)uploadPostFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadPostFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadCommentFromSelf:YES];
        });
        
        return;
    }

    if([syncKickstartTimerOutgoing isValid])
        [syncKickstartTimerOutgoing invalidate]; //init is done, no need for timer. post, comment and image will recurse automatically.
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        //get the posts need to be uploaded
        
        FMResultSet *rs = [db executeQuery:@"select * from post where post_id IS NULL or post_id = ?",[NSNumber numberWithInt:0]];
        
        NSMutableArray *rsArray = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            
            NSDictionary *dict = @{
                                   @"PostTopic":[rs stringForColumn:@"post_topic"],
                                   @"PostBy":[rs stringForColumn:@"post_by"],
                                   @"PostType":[rs stringForColumn:@"post_type"],
                                   @"Severity":[NSNumber numberWithInt:[rs intForColumn:@"severity"]],
                                   @"ActionStatus":[rs stringForColumn:@"status"],
                                   @"ClientPostId":[NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]],
                                   @"BlkId":[NSNumber numberWithInt:[rs intForColumn:@"block_id"]],
                                   @"Location":[rs stringForColumn:@"address"],
                                   @"PostalCode":[rs stringForColumn:@"postal_code"],
                                   @"Level":[rs stringForColumn:@"level"],
                                   @"IsUpdated":[NSNumber numberWithBool:NO],
                                   @"PostGroup": [NSNumber numberWithInt:[rs intForColumn:@"contract_type"]]
                                   };
            
            
            [rsArray addObject:dict];
            
            dict = nil;
        }
        
        if(rsArray.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
                return;
            }
        }
        
        
        NSMutableArray *postListArray     = [[NSMutableArray alloc] init];
        NSMutableDictionary *postListDict = [[NSMutableDictionary alloc] init];
        
        for (int i = 0; i < rsArray.count; i++) {
            NSDictionary *dict = [rsArray objectAtIndex:i];
            
            [postListArray addObject:dict];
            
            dict = nil;
        }
        
        [postListDict setObject:postListArray forKey:@"postList"];

        
        if(postListArray.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
                return;
            }
        }
        
        self.uploadPostFromSelfIsFinished = NO;
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_post_send] parameters:postListDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if(stop)
                return;
            
            self.uploadPostFromSelfIsFinished = YES;
            
            NSDictionary *dict = (NSDictionary *)responseObject;
            NSArray *arr = [dict objectForKey:@"AckPostObj"];
            
            for (int i = 0; i < arr.count; i++) {
                
                NSDictionary *dict = [arr objectAtIndex:i];
                
                NSNumber *clientPostId = [dict valueForKey:@"ClientPostId"];
                NSNumber *postId = [dict valueForKey:@"PostId"];
                NSDate *DueDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"DueDate"]];
                NSNumber *HorticultureBlkId = [dict valueForKey:@"HorticultureBlkId"];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    
                    [theDb  executeUpdate:@"update post set post_id = ?, dueDate = ? where client_post_id = ?",postId, DueDate, clientPostId];
                    
                    //update horticulture block
                    if([HorticultureBlkId intValue] > 0)
                        [theDb executeUpdate:@"update post set block_id = ? where client_post_id = ?",HorticultureBlkId,clientPostId];
                    
                    BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_id = ? where client_post_id = ?",postId, clientPostId];
                    
                    if(!qPostImage)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    BOOL qComment = [theDb executeUpdate:@"update comment set post_id = ? where client_post_id = ?",postId, clientPostId];
                    
                    if(!qComment)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    BOOL qPostStatus = [theDb executeUpdate:@"update post_close_issue_remarks set post_id = ? where client_post_id = ?",postId, clientPostId];
                    if(!qPostStatus)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    
                    BOOL qFeedBackIssue = [theDb executeUpdate:@"update su_feedback_issue set post_id = ? where client_post_id = ?",postId, clientPostId];
                    if(!qFeedBackIssue)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        //update the status of this survey so we can upload it
                        FMResultSet *rsGetIssueFeedBackIssueDets = [db executeQuery:@"select client_feedback_id from su_feedback_issue where post_id = ?",postId];
                        NSNumber *clientSurveyIdForThisPost;
                        
                        while ([rsGetIssueFeedBackIssueDets next]) {
                            FMResultSet *rsGetFeedBackDets = [db executeQuery:@"select client_survey_id from su_feedback where client_feedback_id = ?",[NSNumber numberWithInt:[rsGetIssueFeedBackIssueDets intForColumn:@"client_feedback_id"]]];
                            
                            while ([rsGetFeedBackDets next]) {
                                clientSurveyIdForThisPost = [NSNumber numberWithInt:[rsGetFeedBackDets intForColumn:@"client_survey_id"]];
                            }
                        }
                        
                        BOOL upSurvey = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ?",[NSNumber numberWithInt:1],clientSurveyIdForThisPost];
                        
                        if(!upSurvey)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    
                    BOOL upReassignPost = [theDb executeUpdate:@"update post_reassign set post_id = ? where client_post_id = ?",postId,clientPostId];
                    if(!upReassignPost)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                }];
            }
            
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadPostFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
            }
        }];
    }];
}


- (void)uploadCommentFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadCommentFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadPostStatusChangeFromSelf:YES];
        });
        
        return;
    }
    
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    NSMutableArray *commentListArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *commentListDict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //update comment and post relationship first
        FMResultSet *rsComment = [db executeQuery:@"select * from comment where post_id is null or post_id = ? and comment order by comment_on asc",zero];
        
        while ([rsComment next]) {
            
            NSNumber *comment_client_post_id = [NSNumber numberWithInt:[rsComment intForColumn:@"client_post_id"]];
            
            FMResultSet *rsPost = [db executeQuery:@"select * from post where client_post_id = ?",comment_client_post_id];
            
            while ([rsPost next]) {
                NSNumber *post_client_id = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
                
                BOOL commentUpQ = [db executeUpdate:@"update comment set post_id = ? where client_post_id = ?",post_client_id,comment_client_post_id];
                
                if(!commentUpQ)
                {
                    *rollback = YES;
                    return;
                }
            }
        }
        
        FMResultSet *rs = [db executeQuery:@"select * from comment where comment_id  is null or comment_id = ? order by comment_on asc",zero];
        
        while ([rs next]) {
            NSNumber *ClientCommentId = [NSNumber numberWithInt:[rs intForColumn:@"client_comment_id"]];
            NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSString *CommentString = [rs stringForColumn:@"comment"];
            NSString *CommentBy = [rs stringForColumn:@"comment_by"];
            NSString *CommentType = [rs stringForColumn:@"comment_type"];
            
            NSDictionary *dict = @{ @"ClientCommentId": ClientCommentId , @"PostId" : postId ,@"CommentString" : CommentString , @"CommentBy" : CommentBy , @"CommentType" : CommentType};
            
            
            //post_id zero not allowed
            if([postId intValue] > 0)
                [commentListArray addObject:dict];
            
            dict = nil;
        }
        
        [commentListDict setObject:commentListArray forKey:@"commentList"];
        
        NSDictionary *dict = commentListDict;
        
        NSArray *commentList = [dict objectForKey:@"commentList"];
        if(commentList.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostStatusChangeFromSelf:YES];
                });
                
                return;
            }
        }
        
        self.uploadCommentFromSelfIsFinished = NO;
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_comment_send] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            self.uploadCommentFromSelfIsFinished = YES;
            
            NSArray *arr = [responseObject objectForKey:@"AckCommentObj"];
            
            for(int i = 0; i < arr.count; i++)
            {
                NSDictionary *dict = [arr objectAtIndex:i];
                
                NSNumber *clientCommentId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientCommentId"] intValue]];
                NSNumber *commentId = [NSNumber numberWithInt:[[dict valueForKey:@"CommentId"] intValue]];
                
                BOOL qComment = [db executeUpdate:@"update comment set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qComment)
                {
                    *rollback = YES;
                    return;
                }
                
                BOOL qCommentImage = [db executeUpdate:@"update post_image set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qCommentImage)
                {
                    *rollback = YES;
                    return;
                }
                
            }
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostStatusChangeFromSelf:YES];
                });
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadCommentFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    
                    [self uploadPostStatusChangeFromSelf:YES];
                });
            }
        }];
    }];
}

- (void)uploadPostStatusChangeFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadPostStatusChangeFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadCommentNotiAlreadyReadFromSelf:YES];
        });
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        FMResultSet *rs = [db executeQuery:@"select * from post where statusWasUpdated = ? and post_id is not null",[NSNumber numberWithBool:YES]];
        
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        NSMutableArray *closedPosts = [[NSMutableArray alloc] init];
        
        while([rs next])
        {
            NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSNumber *status = [NSNumber numberWithInt:[rs intForColumn:@"status"]];
            int theStatus = [rs intForColumn:@"status"];
            
            NSDictionary *postList;
            
            if(theStatus == 4) //close
            {
                //get close action remarks
                FMResultSet *rsCloseActionRemarks = [db executeQuery:@"select * from post_close_issue_remarks where post_id = ? and uploaded = ?",postId,[NSNumber numberWithInt:0]];
                
                NSString *ActionRemark = @"";
                NSString *ActionTaken = @"";
                
                while ([rsCloseActionRemarks next]) {
                    ActionRemark = [rsCloseActionRemarks stringForColumn:@"remarks"] ? [rsCloseActionRemarks stringForColumn:@"remarks"] : @"";
                    ActionTaken = [rsCloseActionRemarks stringForColumn:@"actions_taken"] ? [rsCloseActionRemarks stringForColumn:@"actions_taken"] : @"";
                }
                
                postList = @{@"PostId":postId,@"ActionStatus":status,@"ActionRemark":ActionRemark,@"ActionTaken":ActionTaken};
                
                //save the closed posts so we can update the 'uploaded' status after the request
                [closedPosts addObject:postId];
            }
            else
                postList = @{@"PostId":postId,@"ActionStatus":status};
            
            
            [posts addObject:postList];
        }
        
        if(posts.count == 0)
        {
            if(thisSelf == YES)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentNotiAlreadyReadFromSelf:YES];
                });
            }
            
            return;
        }
        
        NSDictionary *dict = @{@"postList":posts};
        
        self.uploadPostStatusChangeFromSelfIsFinished = NO;
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_update_post_status] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            if(stop)
                return;
            
            self.uploadPostStatusChangeFromSelfIsFinished = YES;
            
            NSDictionary *dict = (NSDictionary *) responseObject;
            NSArray *dictArr   = (NSArray *)[dict objectForKey:@"AckPostObj"];
            
            for (int i = 0 ; i < dictArr.count; i ++) {
                NSDictionary *postAck = [dictArr objectAtIndex:i];
                
                NSNumber *postId = [NSNumber numberWithInt:[[postAck valueForKey:@"PostId"] intValue]];
                NSString *error = [postAck valueForKey:@"ErrorMessage"];
                NSNumber *statusWasUpdatedNo = [NSNumber numberWithBool:NO];
                
                if([error isEqualToString:@"Successful"] == YES)
                {
                    BOOL upPostStat = [db executeUpdate:@"update post set statusWasUpdated = ? where post_id = ?",statusWasUpdatedNo,postId];
                    
                    if(!upPostStat)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    for (int cp = 0; cp < closedPosts.count; cp++) {
                        NSNumber *closedPostId = [closedPosts objectAtIndex:cp];
                       
                        BOOL upPostStatClose = [db executeUpdate:@"update post_close_issue_remarks set uploaded = ? where post_id = ?",[NSNumber numberWithInt:1],closedPostId];
                        
                        if(!upPostStatClose)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    
                }
                
                if(thisSelf)
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self uploadCommentNotiAlreadyReadFromSelf:YES];
                    });
                }

            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadPostStatusChangeFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentNotiAlreadyReadFromSelf:YES];
                });
            }
            
        }];
        
    }];
}

- (void)uploadCommentNotiAlreadyReadFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadCommentNotiAlreadyReadFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadImageFromSelf:YES];
        });
        
        return;
    }
    
    NSMutableArray *posts = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *commentNotiUp = [db executeQuery:@"select * from comment_noti where status = ? and uploaded = ?",[NSNumber numberWithInt:2],[NSNumber numberWithBool:NO]];
        
        while ([commentNotiUp next]) {
            NSNumber *postId = [NSNumber numberWithInt:[commentNotiUp intForColumn:@"post_id"]];
            NSNumber *commentId = [NSNumber numberWithInt:[commentNotiUp intForColumn:@"comment_id"]];
            NSString *userId = [commentNotiUp stringForColumn:@"user_id"];
            NSNumber *status = [NSNumber numberWithInt:2];
            
            NSDictionary *rows = [NSDictionary dictionaryWithObjectsAndKeys:postId,@"PostId",commentId,@"CommentId",userId,@"UserId",status,@"Status", nil];
            
            [posts addObject:rows];
            
            rows = nil;
        }
    }];
    
    
    if(posts.count == 0)
    {
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadImageFromSelf:YES];
            });
        }
        return;
    }
    
    
    NSDictionary *params = @{@"commentNotiList":posts};
    
    self.uploadCommentNotiAlreadyReadFromSelfIsFinished = NO;
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        self.uploadCommentNotiAlreadyReadFromSelfIsFinished = YES;
        
        NSDictionary *AckCommentNotiObj = (NSDictionary *)responseObject;
       
        NSArray *postsAckArray = [AckCommentNotiObj objectForKey:@"AckCommentNotiObj"];
        
        for (int i = 0; i < postsAckArray.count; i++) {
            NSDictionary *ackDict   = (NSDictionary *)[postsAckArray objectAtIndex:i];
            NSNumber *CommentId     = [NSNumber numberWithInt:[[ackDict valueForKey:@"CommentId"] intValue]];
            NSNumber *PostId        = [NSNumber numberWithInt:[[ackDict valueForKey:@"PostId"] intValue]];
            NSString *UserId        = [ackDict valueForKey:@"UserId"];
            BOOL IsSuccessful       = [[ackDict valueForKey:@"IsSuccessful"] boolValue];
            
            if(IsSuccessful)
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL up = [db executeUpdate:@"update comment_noti set uploaded = ? where post_id = ? and comment_id = ? and user_id = ?",[NSNumber numberWithBool:YES],PostId,CommentId,UserId];
                    
                    if(!up)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
        }
        
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadImageFromSelf:YES];
            });
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        self.uploadCommentNotiAlreadyReadFromSelfIsFinished = YES;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadImageFromSelf:YES];
            });
        }
    }];
    
}


- (void)uploadImageFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadImageFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadInspectionResultFromSelf:YES];
        });
        
        return;
    }
    
    __block NSMutableDictionary *imagesDict = [[NSMutableDictionary alloc] init];
    
    __block NSMutableArray *imagesInDb = [[NSMutableArray alloc] init];
    
    //get images to send!
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"select * from post_image where post_image_id is null or post_image_id = ? limit 0, 1",[NSNumber numberWithInt:0]];

        while ([rs next]) {
            NSNumber *ImageType = [NSNumber numberWithInt:[rs intForColumn:@"image_type"]];
            NSNumber *CilentPostImageId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_image_id"]];
            NSNumber *PostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSNumber *CommentId = [NSNumber numberWithInt:[rs intForColumn:@"comment_id"]];
            NSString *CreatedBy = [myDatabase.userDictionary valueForKey:@"user_id"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[rs stringForColumn:@"image_path"]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
                continue ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            NSString *imageString = [imageData base64EncodedStringWithSeparateLines:NO];
            
            if([ImageType intValue] == 1)//post image
            {
                CommentId = [NSNumber numberWithInt:0];
            }
            else if([ImageType intValue] == 2)
            {
                PostId = [NSNumber numberWithInt:0];
            }
            
            
            NSDictionary *dict = @{@"CilentPostImageId":CilentPostImageId,@"PostId":PostId,@"CommentId":CommentId,@"CreatedBy":CreatedBy,@"ImageType":ImageType,@"Image":imageString};
            
            [imagesInDb addObject:dict];
        }
        [imagesDict setObject:imagesInDb forKey:@"postImageList"];
    }];
    
    
    NSArray *imagesArray_temp = [imagesDict objectForKey:@"postImageList"];
    if (imagesArray_temp.count == 0) {
        
        imagesInDb = nil;

        if(thisSelf)
        {
                                                                // call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
            return;
        }
    }
    imagesArray_temp = nil;
    
    self.uploadImageFromSelfIsFinished = NO;
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_send_images] parameters:imagesDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        self.uploadImageFromSelfIsFinished = YES;
        
        imagesInDb = nil;
        
        NSArray *arr = [responseObject objectForKey:@"AckPostImageObj"];
        
        for (int i = 0; i < arr.count; i++) {
            NSDictionary *dict = [arr objectAtIndex:i];
            
            NSNumber *ClientPostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientPostImageId"] intValue]];
            NSNumber *PostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"PostImageId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_image_id = ?, uploaded = ? where client_post_image_id = ?  ",PostImageId,@"YES",ClientPostImageId];
                
                if(!qPostImage)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        if(thisSelf)
        {
                                                                    //call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        self.uploadImageFromSelfIsFinished = YES;
        
        imagesInDb = nil;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);

        if(thisSelf)
        {
                                                                    //call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
        }
    }];
}


#pragma mark - upload inspection result
- (void)uploadInspectionResultFromSelf:(BOOL)thisSelf
{
    //skip this method
    if(thisSelf)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadSurveyFromSelf:YES];
        });
    }
    return;
    
    //////
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadInspectionResultFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadSurveyFromSelf:YES];
        });
        
        return;
    }
    
    NSMutableArray *inspArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSNumber *requiredSync = [NSNumber numberWithInt:1];
        
        FMResultSet *rs = [db executeQuery:@"select * from ro_inspectionresult where w_required_sync = ? limit 1,10",requiredSync];
        
        
        while ([rs next]) {

            NSNumber *ScheduleId = [NSNumber numberWithInt:[rs intForColumn:@"w_scheduleid"]];
            NSNumber *CheckListId = [NSNumber numberWithInt:[rs intForColumn:@"w_checklistid"]];
            NSNumber *ChkAreaId = [NSNumber numberWithInt:[rs intForColumn:@"w_chkareaid"]];
            NSString *ReportBy = [rs stringForColumn:@"w_reportby"];
            NSNumber *Checked = [NSNumber numberWithInt:[rs intForColumn:@"w_checked"]];
            NSNumber *SPOChecked = [NSNumber numberWithInt:[rs intForColumn:@"w_spochecked"]];
            
            NSDictionary *dict = @{ @"ScheduleId" : ScheduleId , @"CheckListId": CheckListId , @"ChkAreaId" : ChkAreaId, @"ReportBy" : ReportBy, @"Checked" :  Checked , @"SPOChecked" : SPOChecked};
            
            [inspArr addObject:dict];
        }
        
     }];
    
    if(inspArr.count == 0)
    {
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadSurveyFromSelf:YES];
            });
        }
        return;
    }
    
    NSDictionary *inspDict = @{@"inspectionResultList":inspArr};
    
    self.uploadInspectionResultFromSelfIsFinished = NO;
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_inspection_res] parameters:inspDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
       if(stop)return;
       
       self.uploadInspectionResultFromSelfIsFinished = YES;
       
       NSDictionary *topDict = (NSDictionary *)responseObject;
       
       NSArray *AckInspectionResultObj = [topDict objectForKey:@"AckInspectionResultObj"];
       
       for (int i = 0; i < AckInspectionResultObj.count; i++) {
           NSDictionary *dict = [AckInspectionResultObj objectAtIndex:i];
           
           NSNumber *CheckListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
           NSNumber *ChkAreaId = [NSNumber numberWithInt:[[dict valueForKey:@"ChkAreaId"] intValue]];
           NSNumber *ScheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleId"] intValue]];
           BOOL Successful = [[dict valueForKey:@"Successful"] boolValue];
           
           if(Successful)
           {
               [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                   NSNumber *syncNotRequired = [NSNumber numberWithInt:0];
                   BOOL up = [db executeUpdate:@"update ro_inspectionresult set w_required_sync = ? where w_checklistid = ? and w_chkareaid = ? and w_scheduleid = ?",syncNotRequired,CheckListId,ChkAreaId,ScheduleId];
                   
                   if(!up)
                   {
                       *rollback = YES;
                       return;
                   }
               }];
           }
       }
       
       if(thisSelf)
       {
                                                                    // call this faster
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [self uploadSurveyFromSelf:YES];
           });
       }
       
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
       if(stop)return;
       
       self.uploadInspectionResultFromSelfIsFinished = YES;
       
       DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
       
       if(thisSelf)
       {
                                                                    // call this faster
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [self uploadSurveyFromSelf:YES];
           });
       }
   }];
}


#pragma mark - upload survey
- (void)uploadSurveyFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadSurveyFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadCrmFromSelf:YES];
        });
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSMutableDictionary *surveyDict = [[NSMutableDictionary alloc] init];
        NSDictionary *surveyContainer;
        
        BOOL doUpload = NO;

        FMResultSet *rsSurvey = [db executeQuery:@"select * from su_survey where status = ? order by survey_date desc limit 0, 1",[NSNumber numberWithInt:1]];
        
        while ([rsSurvey next]) {
            doUpload = YES;
            
            int ClientSurveyId = [rsSurvey intForColumn:@"client_survey_id"];
            int ClientSurveyAddressId = [rsSurvey intForColumn:@"client_survey_address_id"];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
            NSDate *surveyNsDate = [rsSurvey dateForColumn:@"survey_date"];
            NSString *surveyDateJsonString = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [surveyNsDate timeIntervalSince1970],[formatter stringFromDate:surveyNsDate]];
            
            NSString *ResidentName = [rsSurvey stringForColumn:@"resident_name"] ? [rsSurvey stringForColumn:@"resident_name"] : @"";
            NSString *ResidentAgeRange = [rsSurvey stringForColumn:@"resident_age_range"] ? [rsSurvey stringForColumn:@"resident_age_range"] : @"";
            NSString *ResidentGender = [rsSurvey stringForColumn:@"resident_gender"] ? [rsSurvey stringForColumn:@"resident_gender"] : @"";
            NSString *ResidentRace = [rsSurvey stringForColumn:@"resident_race"] ? [rsSurvey stringForColumn:@"resident_race"] : @"";
            int ClientResidentAddressId = [rsSurvey intForColumn:@"client_resident_address_id"];
            NSString *ResidentContact = [rsSurvey stringForColumn:@"resident_contact"] ? [rsSurvey stringForColumn:@"resident_contact"] : @"" ;
            NSString *Resident2ndContact = [rsSurvey stringForColumn:@"other_contact"] ? [rsSurvey stringForColumn:@"other_contact"] : @"" ;
            NSString *ResidentEmail = [rsSurvey stringForColumn:@"resident_email"] ? [rsSurvey stringForColumn:@"resident_email"] : @"" ;
            NSNumber *DataProtection = [NSNumber numberWithInt:[rsSurvey intForColumn:@"data_protection"]];
            NSString *CreatedBy = [rsSurvey stringForColumn:@"created_by"] ? [rsSurvey stringForColumn:@"created_by"] : @"";
            NSNumber *IsMine = [NSNumber numberWithBool:[rsSurvey boolForColumn:@"isMine"]];
            
            [surveyDict setObject:[NSNumber numberWithInt:ClientSurveyId] forKey:@"ClientSurveyId"];
            [surveyDict setObject:[NSNumber numberWithInt:ClientSurveyAddressId] forKey:@"ClientSurveyAddressId"];
            [surveyDict setObject:surveyDateJsonString forKey:@"SurveyDate"];
            [surveyDict setObject:ResidentName forKey:@"ResidentName"];
            [surveyDict setObject:ResidentAgeRange forKey:@"ResidentAgeRange"];
            [surveyDict setObject:ResidentGender forKey:@"ResidentGender"];
            [surveyDict setObject:ResidentRace forKey:@"ResidentRace"];
            [surveyDict setObject:[NSNumber numberWithInt:ClientResidentAddressId] forKey:@"ClientResidentAddressId"];
            [surveyDict setObject:ResidentContact forKey:@"ResidentContact"];
            [surveyDict setObject:Resident2ndContact forKey:@"Resident2ndContact"];
            [surveyDict setObject:ResidentEmail forKey:@"ResidentEmail"];
            [surveyDict setObject:DataProtection forKey:@"DataProtection"];
            [surveyDict setObject:CreatedBy forKey:@"CreatedBy"];
            [surveyDict setObject:IsMine forKey:@"IsMine"];
            
            //get answers list
            FMResultSet *rsAnswers = [db executeQuery:@"select * from su_answers where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *answersArray = [[NSMutableArray alloc] init];
            while ([rsAnswers next]) {
                NSNumber *ClientAnswerId = [NSNumber numberWithInt:[rsAnswers intForColumn:@"client_answer_id"]];
                NSNumber *QuestionId = [NSNumber numberWithInt:[rsAnswers intForColumn:@"question_id"]];
                NSNumber *Rating = [NSNumber numberWithInt:[rsAnswers intForColumn:@"rating"]];
                
                NSDictionary *dictRowAnswers = @{@"ClientAnswerId":ClientAnswerId,@"QuestionId":QuestionId,@"Rating":Rating};
                
                [answersArray addObject:dictRowAnswers];
            }
            
            [surveyDict setObject:answersArray forKey:@"AnswerList"];
            
            
            //get feedbacks issue
            FMResultSet *rsFeedbackIssuesList = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *rsfiArr = [[NSMutableArray alloc] init];
            while ([rsFeedbackIssuesList next]) {
                NSNumber *client_feedback_id = [NSNumber numberWithInt:[rsFeedbackIssuesList intForColumn:@"client_feedback_id"]];
                
                //get su_feedback_issue
                FMResultSet *rsFI = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ?",client_feedback_id];

                while ([rsFI next]) {
                    NSNumber *ClientFeedbackIssueId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_feedback_issue_id"]];
                    NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_feedback_id"]];
                    
                    NSNumber *PostId = [NSNumber numberWithInt:[rsFI intForColumn:@"post_id"]];
                    NSNumber *ClientPostId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_post_id"]];
                    
                    if([ClientPostId intValue] > 0 && [PostId intValue] == 0) //this post was not yet uploaded, don't upload this survey
                    {
                        doUpload = NO;
                        continue;
                    }
                    
                    NSString *IssueDes = [rsFI stringForColumn:@"issue_des"];
                    NSNumber *AutoAssignMe = [NSNumber numberWithBool:[rsFI boolForColumn:@"auto_assignme"]];
                    
                    NSDictionary *rsFIDict = @{@"ClientFeedbackIssueId":ClientFeedbackIssueId,@"ClientFeedbackId":ClientFeedbackId,@"PostId":PostId,@"IssueDes":IssueDes,@"AutoAssignMe":AutoAssignMe};
                    
                    [rsfiArr addObject:rsFIDict];
                }
            }
            
            [surveyDict setObject:rsfiArr forKey:@"FeedbackIssueList"];
            
            //get address
            NSMutableArray *addressArray = [[NSMutableArray alloc] init];
            
            //get the addresses base on survey address
            FMResultSet *rsAddressSurvey = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:ClientSurveyAddressId]];
            
            while ([rsAddressSurvey next]) {
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddressSurvey intForColumn:@"client_address_id"]];
                NSString *Location = [rsAddressSurvey stringForColumn:@"address"] ? [rsAddressSurvey stringForColumn:@"address"] : @"";
                NSString *UnitNo = [rsAddressSurvey stringForColumn:@"unit_no"] ? [rsAddressSurvey stringForColumn:@"unit_no"] : @"";
                NSString *SpecifyArea = [rsAddressSurvey stringForColumn:@"specify_area"] ? [rsAddressSurvey stringForColumn:@"specify_area"] : @"";
                NSString *PostalCode = [rsAddressSurvey stringForColumn:@"postal_code"] ? [rsAddressSurvey stringForColumn:@"postal_code"] : @"0";
                NSNumber *BlkId = [NSNumber numberWithInt:[rsAddressSurvey intForColumn:@"block_id"]];
                
                NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                
                [addressArray addObject:dictAddSurvey];
            }
            
            //get the addresses base on resident address
            if(ClientResidentAddressId > 0)
            {
                FMResultSet *rsAddressSurvey2 = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:ClientResidentAddressId]];
                
                while ([rsAddressSurvey2 next]) {
                    NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddressSurvey2 intForColumn:@"client_address_id"]];
                    NSString *Location = [rsAddressSurvey2 stringForColumn:@"address"] ? [rsAddressSurvey2 stringForColumn:@"address"] : @"";
                    NSString *UnitNo = [rsAddressSurvey2 stringForColumn:@"unit_no"] ? [rsAddressSurvey2 stringForColumn:@"unit_no"] : @"";
                    NSString *SpecifyArea = [rsAddressSurvey2 stringForColumn:@"specify_area"] ? [rsAddressSurvey2 stringForColumn:@"specify_area"] : @"";
                    NSString *PostalCode = [rsAddressSurvey2 stringForColumn:@"postal_code"] ? [rsAddressSurvey2 stringForColumn:@"postal_code"] : @"0";
                    NSNumber *BlkId = [NSNumber numberWithInt:[rsAddressSurvey2 intForColumn:@"block_id"]];
                    
                    NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                    
                    [addressArray addObject:dictAddSurvey];
                }
            }
            
            
            
            //get the addresses based on feedback
            FMResultSet *rsAddressFeedback = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            while ([rsAddressFeedback next]) {
                NSNumber *client_address_id = [NSNumber numberWithInt:[rsAddressFeedback intForColumn:@"client_address_id"]];
                
                FMResultSet *rsAddFeedBack = [db executeQuery:@"select * from su_address where client_address_id = ?",client_address_id];
                
                while ([rsAddFeedBack next]) {
                    NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddFeedBack intForColumn:@"client_address_id"]];
                    NSString *Location = [rsAddFeedBack stringForColumn:@"address"] ? [rsAddFeedBack stringForColumn:@"address"] : @"";
                    NSString *UnitNo = [rsAddFeedBack stringForColumn:@"unit_no"] ? [rsAddFeedBack stringForColumn:@"unit_no"] : @"";
                    NSString *SpecifyArea = [rsAddFeedBack stringForColumn:@"specify_area"] ? [rsAddFeedBack stringForColumn:@"specify_area"] : @"";
                    NSString *PostalCode = [rsAddFeedBack stringForColumn:@"postal_code"] ? [rsAddFeedBack stringForColumn:@"postal_code"] : @"0";
                    NSNumber *BlkId = [NSNumber numberWithInt:[rsAddFeedBack intForColumn:@"block_id"]];
                    
                    NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                    
                    if([addressArray containsObject:dictAddSurvey] == NO)
                        [addressArray addObject:dictAddSurvey];
                }
            }
            
            [surveyDict setObject:addressArray forKey:@"AddressList"];
            
            
            //get feedback
            FMResultSet *rsFeedBack = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *feedBackArray = [[NSMutableArray alloc] init];
            
            while ([rsFeedBack next]) {
                NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[rsFeedBack intForColumn:@"client_feedback_id"]];
                NSString *Description = [rsFeedBack stringForColumn:@"description"];
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsFeedBack intForColumn:@"client_address_id"]];
                
                NSDictionary *dictFeedRow = @{@"ClientFeedbackId":ClientFeedbackId,@"Description":Description,@"ClientAddressId":ClientAddressId};
                
                [feedBackArray addObject:dictFeedRow];
            }
            
            [surveyDict setObject:feedBackArray forKey:@"FeedbackList"];
            
            surveyContainer = @{@"surveyContainer":surveyDict};
            

        } //end of while ([rsSurvey next])
        
        if(doUpload == NO)
        {
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmFromSelf:YES];
                });
            }
            
            return;
        }
        
        self.uploadSurveyFromSelfIsFinished = NO;
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_survey] parameters:surveyContainer success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            self.uploadSurveyFromSelfIsFinished = YES;
            
            NSDictionary *topDict = (NSDictionary *)responseObject;
            
            NSDictionary *AckSurveyContainer = [topDict objectForKey:@"AckSurveyContainer"];
            
            NSArray *AckAddressList = [AckSurveyContainer objectForKey:@"AckAddressList"];
            NSArray *AckAnswerList = [AckSurveyContainer objectForKey:@"AckAnswerList"];
            NSArray *AckFeedbackIssueList = [AckSurveyContainer objectForKey:@"AckFeedbackIssueList"];
            NSArray *AckFeedbackList = [AckSurveyContainer objectForKey:@"AckFeedbackList"];
            
            NSNumber *ClientSurveyId = [NSNumber numberWithInt:[[AckSurveyContainer valueForKey:@"ClientSurveyId"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[AckSurveyContainer valueForKey:@"SurveyId"] intValue]];
            
            BOOL massUpdateOk = YES;
            
            //update survey
            BOOL upSurvey = [db executeUpdate:@"update su_survey set survey_id = ? where client_survey_id = ?",SurveyId,ClientSurveyId];
            if(!upSurvey)
            {
                *rollback = YES;
                return;
            }
            
            //update answers
            for (int i = 0; i < AckAnswerList.count; i++) {
                NSNumber *AnswerId = [NSNumber numberWithInt:[[[AckAnswerList objectAtIndex:i] valueForKey:@"AnswerId"] intValue]];
                NSNumber *ClientAnswerId = [NSNumber numberWithInt:[[[AckAnswerList objectAtIndex:i] valueForKey:@"ClientAnswerId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_answers set answer_id = ?, survey_id = ? where client_answer_id = ?",AnswerId,SurveyId,ClientAnswerId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
            }
            
            
            //update address
            for (int i = 0; i < AckAddressList.count; i++) {
                NSNumber *AddressId = [NSNumber numberWithInt:[[[AckAddressList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[[[AckAddressList objectAtIndex:i] valueForKey:@"ClientAddressId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_address set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];
                

                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
                
                //update survey_address_id and resident_address_id
                BOOL upSuAdds = [db executeUpdate:@"update su_survey set survey_address_id = ? where client_survey_address_id = ?",AddressId,ClientAddressId];
                BOOL upSuAdds2 = [db executeUpdate:@"update su_survey set resident_address_id = ? where client_resident_address_id = ?",AddressId,ClientAddressId];
                
                
                //update feedback address_id
                BOOL feedAddId = [db executeUpdate:@"update su_feedback set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];
            }
            
            
            //update AckFeedbackIssueList
            for (int i = 0; i < AckFeedbackIssueList.count; i++) {

                NSNumber *ClientFeedbackIssueId = [NSNumber numberWithInt:[[[AckFeedbackIssueList objectAtIndex:i] valueForKey:@"ClientFeedbackIssueId"] intValue]];
                NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[[AckFeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackIssueId"] intValue]];
                
                
                BOOL upAns = [db executeUpdate:@"update su_feedback_issue set feedback_issue_id = ? where client_feedback_issue_id = ?",FeedbackIssueId,ClientFeedbackIssueId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
                
                //update crm
                BOOL upCrm = [db executeUpdate:@"update suv_crm set feedback_issue_id = ? where client_feed_back_issue_id = ?",FeedbackIssueId,ClientFeedbackIssueId];
                if(!upCrm)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            
            //update AckFeedbackList
            for (int i = 0; i < AckFeedbackList.count; i++) {
                NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[[[AckFeedbackList objectAtIndex:i] valueForKey:@"ClientFeedbackId"] intValue]];
                NSNumber *FeedbackId = [NSNumber numberWithInt:[[[AckFeedbackList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_feedback set feedback_id = ?, survey_id = ? where client_feedback_id = ?",FeedbackId,SurveyId,ClientFeedbackId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
                
                //update feedback_issue
                BOOL upFbI = [db executeUpdate:@"update su_feedback_issue set feedback_id = ? where client_feedback_id = ?",FeedbackId,ClientFeedbackId];

                if(!upFbI)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            if(massUpdateOk == YES)
            {
                BOOL upSurveySync = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ?",[NSNumber numberWithInt:0],ClientSurveyId];
                if(!upSurveySync)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadSurveyFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmFromSelf:YES];
                });
            }
        }];
        
    }];
}


#pragma mark - upload crm
- (void)uploadCrmFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadCrmFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadCrmImageFromSelf:YES];
        });
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSMutableDictionary *crmDict = [[NSMutableDictionary alloc] init];

        
        FMResultSet *rsCrm = [db executeQuery:@"select * from suv_crm where crm_id = ?",[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
        
        NSMutableArray *crmIssuetList = [[NSMutableArray alloc] init];
        
        while ([rsCrm next]) {
            
            if([rsCrm intForColumn:@"feedback_issue_id"] == 0)
                continue;
            
            NSNumber *ClientCRMIssueId = [NSNumber numberWithInt:[rsCrm intForColumn:@"client_crm_id"]];
            NSString *Body = [rsCrm stringForColumn:@"description"] ? [rsCrm stringForColumn:@"description"] : @"";
            NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[rsCrm intForColumn:@"feedback_issue_id"]];
            NSString *PostalCode = [rsCrm stringForColumn:@"postal_code"] ? [rsCrm stringForColumn:@"postal_code"] : @"";
            NSString *Address = [rsCrm stringForColumn:@"address"] ? [rsCrm stringForColumn:@"address"] : @"";
            NSString *Level = [rsCrm stringForColumn:@"level"] ? [rsCrm stringForColumn:@"level"] : @"";
            NSNumber *NoOfImage = [NSNumber numberWithInt:[rsCrm intForColumn:@"no_of_image"]];
            
            NSDictionary *dict = @{@"ClientCRMIssueId":ClientCRMIssueId,@"Body":Body,@"FeedbackIssueId":FeedbackIssueId,@"PostalCode":PostalCode,@"Address":Address,@"Level":Level,@"NoOfImage":NoOfImage};
            
            [crmIssuetList addObject:dict];
        }
        
        [crmDict setObject:crmIssuetList forKey:@"crmIssuetList"];
        
        if(crmIssuetList.count == 0)
        {
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmImageFromSelf:YES];
                });
            }
            
            return ;
        }
        
        self.uploadCrmFromSelfIsFinished = NO;
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_crm] parameters:crmDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            self.uploadCrmFromSelfIsFinished = YES;
            
            NSDictionary *topDict = (NSDictionary *)responseObject;
            
            NSArray *AckCRMIssueObj = [topDict objectForKey:@"AckCRMIssueObj"];
            
            for (int i = 0; i < AckCRMIssueObj.count; i++) {
                NSDictionary *dict = [AckCRMIssueObj objectAtIndex:i];
                
                NSNumber *CRMIssueId = [NSNumber numberWithInt:[[dict valueForKey:@"CRMIssueId"] intValue]];
                NSNumber *ClientCRMIssueId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientCRMIssueId"] intValue]];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL upCrm = [db executeUpdate:@"update suv_crm set crm_id = ? where client_crm_id = ?",CRMIssueId,ClientCRMIssueId];

                    if (!upCrm) {
                        *rollback = YES;
                        return;
                    }
                    
                    BOOL upCrmImg = [db executeUpdate:@"update suv_crm_image set crm_id = ? where client_crm_id = ?",CRMIssueId,ClientCRMIssueId];
                    if(!upCrmImg)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
                
            }
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmImageFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadCrmFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCrmImageFromSelf:YES];
                });
            }
        }];
        
    }];
}


#pragma mark - upload crm image
- (void)uploadCrmImageFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadCrmImageFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadReassignPostFromSelf:YES];
        });
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        NSMutableDictionary *crmDict = [[NSMutableDictionary alloc] init];
        
        FMResultSet *rsCrm = [db executeQuery:@"select * from suv_crm_image where crm_image_id = ? and image_path is not null limit 0, 1",[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
        
        NSMutableArray *crmImageList = [[NSMutableArray alloc] init];
        
        while ([rsCrm next]) {
            
            if([rsCrm intForColumn:@"crm_id"] == 0)
                continue;
            
            NSNumber *CilentCRMImageId = [NSNumber numberWithInt:[rsCrm intForColumn:@"client_crm_image_id"]];
            NSNumber *CRMId = [NSNumber numberWithInt:[rsCrm intForColumn:@"crm_id"]];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[rsCrm stringForColumn:@"image_path"]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
                continue ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            NSString *imageString = [imageData base64EncodedStringWithSeparateLines:NO];
            
            NSString *Image = imageString;
            
            NSDictionary *dict = @{@"CilentCRMImageId":CilentCRMImageId,@"CRMId":CRMId,@"Image":Image};
            
            [crmImageList addObject:dict];
        }
        
        if(crmImageList.count == 0)
        {
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadReassignPostFromSelf:YES];
                });
            }
            
            return;
        }
        
        
        [crmDict setObject:crmImageList forKey:@"crmImageList"];

        self.uploadCrmImageFromSelfIsFinished = NO;
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_crm_image] parameters:crmDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            self.uploadCrmImageFromSelfIsFinished = YES;
            
            NSDictionary *topDict = (NSDictionary *)responseObject;
            //do db stuff
            
            NSArray *AckCRMImageObj = [topDict objectForKey:@"AckCRMImageObj"];
            
            for (int i = 0; i < AckCRMImageObj.count; i++) {
                NSDictionary *dict = [AckCRMImageObj objectAtIndex:i];
                NSNumber *CilentCRMImageId = [NSNumber numberWithInt:[[dict valueForKey:@"CilentCRMImageId"] intValue]];
                NSNumber *CRMImageId = [NSNumber numberWithInt:[[dict valueForKey:@"CRMImageId"] intValue]];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL upCrmImage = [db executeUpdate:@"update suv_crm_image set crm_image_id = ?, uploaded = ? where client_crm_image_id = ?",CRMImageId,[NSNumber numberWithInt:1],CilentCRMImageId];
                    
                    if(!upCrmImage)
                    {
                        *rollback = YES;
                        return ;
                    }
                }];
            }
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadReassignPostFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadCrmImageFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadReassignPostFromSelf:YES];
                });
            }
        }];
        
    }];
}


#pragma mark - upload reassign posts
- (void)uploadReassignPostFromSelf:(BOOL)thisSelf
{
    
    if(myDatabase.initializingComplete == NO)
        return;
    
    if(!self.uploadReassignPostFromSelfIsFinished)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self uploadPostFromSelf:YES];
        });
        
        return;
    }
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSMutableDictionary *postInfoDict = [[NSMutableDictionary alloc] init];
        
        FMResultSet *rs = [db executeQuery:@"select * from post_reassign where reassign_post_id = ? and post_id <> ?",[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
        
        NSMutableArray *reAssignPostList = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            
            NSNumber *PostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSString *PostGroup = [rs stringForColumn:@"post_group"];
            NSNumber *ClientReAssignPostId = [NSNumber numberWithInt:[rs intForColumn:@"client_reassign_post_id"]];
            
            NSDictionary *dict = @{@"PostId":PostId,@"PostGroup":PostGroup,@"ClientReAssignPostId":ClientReAssignPostId};
            
            [reAssignPostList addObject:dict];
        }
        
        if(reAssignPostList.count == 0)
        {
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostFromSelf:YES];
                });
            }
            
            return;
        }
        
        
        [postInfoDict setObject:reAssignPostList forKey:@"reAssignPostList"];
        
        self.uploadReassignPostFromSelfIsFinished = NO;
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_reassign_posts] parameters:postInfoDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            self.uploadReassignPostFromSelfIsFinished = YES;
            
            NSDictionary *topDict = (NSDictionary *)responseObject;
            //do db stuff
            
            NSArray *AckReAssignPostObj = [topDict objectForKey:@"AckReAssignPostObj"];
            
            for (int i = 0; i < AckReAssignPostObj.count; i++) {
                NSDictionary *dict = [AckReAssignPostObj objectAtIndex:i];
                NSNumber *ClientReAssignPostId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientReAssignPostId"] intValue]];
                NSNumber *ReAssignPostId = [NSNumber numberWithInt:[[dict valueForKey:@"ReAssignPostId"] intValue]];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL upReassignPost = [db executeUpdate:@"update post_reassign set reassign_post_id = ?, is_uploaded = ? where client_reassign_post_id = ?",ReAssignPostId,[NSNumber numberWithInt:1],ClientReAssignPostId];
                    
                    if(!upReassignPost)
                    {
                        *rollback = YES;
                        return ;
                    }
                }];
            }
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            self.uploadReassignPostFromSelfIsFinished = YES;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostFromSelf:YES];
                });
            }
        }];
        
    }];
}

- (void)updatePostAsSeenForPostId:(NSNumber *)postId
{
    if([postId intValue] == 0)
        return;
    
    NSMutableArray *postList = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select post_id from post where post_id = ?",postId];
        
        while ([rs next]) {
            [postList addObject:@{@"PostId":[NSNumber numberWithInt:[rs intForColumn:@"post_id"]]}];
        }
    }];
    
    if(postList.count == 0)
        return;
    
    NSDictionary *params = @{@"postList":postList};
  
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_update_post_as_seen] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"post as seen %@",responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
        
    }];
}


#pragma mark - upload resident info edit: called on demand
- (void)uploadResidentInfoEditForSurveyId:(NSNumber *)surveyId
{
    NSMutableDictionary *surveyContainer = [[NSMutableDictionary alloc] init];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        
        NSMutableArray *addressArray = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            NSNumber *SurveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
            NSString *ResidentName = [rs stringForColumn:@"resident_name"] ? [rs stringForColumn:@"resident_name"] : @"";
            NSString *ResidentAgeRange = [rs stringForColumn:@"resident_age_range"] ? [rs stringForColumn:@"resident_age_range"] : @"";
            NSString *ResidentGender = [rs stringForColumn:@"resident_gender"] ? [rs stringForColumn:@"resident_gender"] : @"";
            NSString *ResidentRace = [rs stringForColumn:@"resident_race"] ? [rs stringForColumn:@"resident_race"] : @"";
            NSString *ResidentContact = [rs stringForColumn:@"resident_contact"] ? [rs stringForColumn:@"resident_contact"] : @"";
            NSString *Resident2ndContact = [rs stringForColumn:@"other_contact"] ? [rs stringForColumn:@"other_contact"] : @"";
            NSString *ResidentEmail = [rs stringForColumn:@"resident_email"] ? [rs stringForColumn:@"resident_email"] : @"";
            NSNumber *ClientResidentAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_resident_address_id"]];
            NSNumber *ResidentAddressId = [NSNumber numberWithInt:[rs intForColumn:@"resident_address_id"]];
            
            
            [surveyContainer setObject:SurveyId forKey:@"SurveyId"];
            [surveyContainer setObject:ResidentName forKey:@"ResidentName"];
            [surveyContainer setObject:ResidentAgeRange forKey:@"ResidentAgeRange"];
            [surveyContainer setObject:ResidentGender forKey:@"ResidentGender"];
            [surveyContainer setObject:ResidentRace forKey:@"ResidentRace"];
            [surveyContainer setObject:ResidentContact forKey:@"ResidentContact"];
            [surveyContainer setObject:Resident2ndContact forKey:@"Resident2ndContact"];
            [surveyContainer setObject:ResidentEmail forKey:@"ResidentEmail"];
            [surveyContainer setObject:ClientResidentAddressId forKey:@"ClientResidentAddressId"];
            [surveyContainer setObject:ResidentAddressId forKey:@"ResidentAddressId"];
            
            
            //get address
            FMResultSet *rsAddres = [db executeQuery:@"select * from su_address where client_address_id = ?",ClientResidentAddressId];
            
            while ([rsAddres next]) {
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddres intForColumn:@"client_address_id"]];
                NSNumber *AddressId = [NSNumber numberWithInt:[rsAddres intForColumn:@"address_id"]];
                NSString *Location = [rsAddres stringForColumn:@"address"] ? [rsAddres stringForColumn:@"address"] : @"";
                NSString *UnitNo = [rsAddres stringForColumn:@"unit_no"] ? [rsAddres stringForColumn:@"unit_no"] : @"";
                NSString *SpecifyArea = [rsAddres stringForColumn:@"specify_area"] ? [rsAddres stringForColumn:@"specify_area"] : @"";
                NSString *PostalCode = [rsAddres stringForColumn:@"postal_code"] ? [rsAddres stringForColumn:@"postal_code"] : @"";
                NSNumber *BlkId = [NSNumber numberWithInt:[rsAddres intForColumn:@"block_id"]];
                
                NSDictionary *dictAd = @{@"ClientAddressId" : ClientAddressId, @"AddressId" : AddressId, @"Location" : Location , @"UnitNo" : UnitNo , @"SpecifyArea" : SpecifyArea, @"PostalCode": PostalCode,@"BlkId":BlkId };
                
                [addressArray addObject:dictAd];
            }
            
            [surveyContainer setObject:addressArray forKey:@"AddressList"];
        }
    }];
    

    NSDictionary *surveyDict = @{@"surveyContainer" : surveyContainer};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_resident_info_edit] parameters:surveyDict success:^(AFHTTPRequestOperation *operation, id responseObject) {

        
        NSDictionary *topDict = (NSDictionary *)responseObject;
        
        NSArray *AckAddress = [topDict objectForKey:@"AckAddress"];
        
        for (int i = 0; i < AckAddress.count; i++) {
            NSDictionary *dict = [AckAddress objectAtIndex:i];
            NSNumber *AddressId = [NSNumber numberWithInt:[[dict valueForKey:@"AddressId"] intValue]];
            NSNumber *ClientAddressId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientAddressId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                BOOL upAddId;
                
                if([ClientAddressId intValue] > 0)
                    upAddId = [db executeUpdate:@"update su_address set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];

                if(!upAddId)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
    }];
}

- (void)startDownloadQuestionsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    __block Questions *questions = [[Questions alloc] init];
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
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
            [self startDownloadQuestionsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
                [questions updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - download new data from server
- (void)startDownloadFeedBackIssuesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_feedback_issues] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"FeedbackIssueContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
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
            [self startDownloadFeedBackIssuesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
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
            }
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}

#pragma mark - download survey
- (void)startDownloadSurveyPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_survey] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
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
            
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_feedback_issue where feedback_issue_id = ?",FeedbackIssueId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_feedback_issue(feedback_id,feedback_issue_id,issue_des,auto_assignme,post_id,Status) values (?,?,?,?,?,?)",FeedbackId,FeedbackIssueId,IssueDes,AutoAssignMe,PostId,Status];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL insUp = [db executeUpdate:@"update su_feedback_issue set feedback_id = ?, feedback_issue_id = ?, issue_des = ?, auto_assignme = ?, post_id = ?, status = ? where feedback_issue_id = ?",FeedbackId,FeedbackIssueId,IssueDes,AutoAssignMe,PostId,Status,FeedbackIssueId];
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
                    BOOL insAdd = [db executeUpdate:@"insert into su_survey(average_rating,resident_address_id,resident_age_range,resident_gender,resident_name,resident_race,survey_address_id,survey_date,survey_id,resident_contact,resident_email,data_protection, other_contact, created_by, isMine) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",AverageRating,ResidentAddressId,ResidentAgeRange,ResidentGender,ResidentName,ResidentRace,SurveyAddressId,SurveyDate,SurveyId,ResidentContact,ResidentEmail,DataProtection, Resident2ndContact, CreatedBy,IsMine];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        
        NSDate *LastRequestDate =  [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSurveyPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
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
            
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadSurveyPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadSurveyPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - download new data from server
- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    __block Post *post = [[Post alloc] init];
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
            
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"PostList"];

        //local notif vars
        NSString *fromUser;
        NSString *msgFromUser;
        
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
            NSNumber *contractType = [NSNumber numberWithInt:[[dictPost valueForKey:@"PostGroup"] intValue]];
            NSNumber *relatedPostId = [NSNumber numberWithInt:[[dictPost valueForKey:@"relatedPostId"] intValue]];
            NSNumber *IsNew = [NSNumber numberWithBool:[[dictPost valueForKey:@"IsNew"] boolValue]];
            
            if([IsNew boolValue] == YES)
                IsNew = [NSNumber numberWithBool:NO];
            else
                IsNew = [NSNumber numberWithBool:YES];
            
            fromUser = PostBy;
            msgFromUser = PostTopic;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select post_id from post where post_id = ?",PostId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date, updated_on,seen,contract_type, dueDate, relatedPostId) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate,LastUpdatedDate,IsNew,contractType,DueDate,relatedPostId];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else //update
                {
                    if([PostId intValue] > 0)
                    {
                        BOOL qUps = [theDb executeUpdate:@"update post set status = ?, block_id = ?, level = ?, address = ?, post_by = ?, post_topic = ?, post_type = ?, postal_code = ?, severity = ?, post_date = ? ,contract_type = ?, dueDate = ?, updated_on = ?, relatedPostId = ?, seen = ?  where post_id = ?",ActionStatus,BlkId,Level,Location,PostBy,PostTopic,PostType,PostalCode,Severity,PostDate,contractType,DueDate,LastUpdatedDate,relatedPostId,IsNew,PostId];
                        
                        if(!qUps)
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
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [post updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
                
                post = nil;
                
                [self reloadIssuesList];
            }
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadPostForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = [self serializedStringDateJson:requestDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
        
        [imagesArr addObject:dict];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostImagesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            [self SavePostImagesToDb];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                
            });
        }
    }];
}


- (void)SavePostImagesToDb
{
    imageDownloadComplete = NO;
    
    NSDictionary *topDict = (NSDictionary *)[imagesArr lastObject];
    NSDate *lastRequestDate = [myDatabase createNSDateWithWcfDateString:[topDict valueForKey:@"LastRequestDate"]];
    NSString *jsonDate = [self serializedStringDateJson:lastRequestDate];
    
    if (imagesArr.count > 0) {
        
        SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
        
        for (int xx = 0; xx < imagesArr.count; xx++) {
            NSDictionary *dict = (NSDictionary *) [imagesArr objectAtIndex:xx];
            
            NSArray *ImageList = [dict objectForKey:@"ImageList"];
            
            if(ImageList.count == 0) //no image to download, set true flag to watch download again
                imageDownloadComplete = YES;
            
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
                    
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    
                    if(image == nil)
                        return;
                    
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
                            
                            [imagesArr removeAllObjects];
                            
                            //start download again
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                
                                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lastRequestDate];
                                
                            });
                        }
                    }];
                    
                    if(CommentId > 0)//the image was in a form of a comment, so we need to reload our chat view to reflect the image
                    {
                        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                        {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadChatView" object:nil];
                            });
                        }
                    }
                }];
                
                if(j >= ImageList.count - 1) //last object
                    [self reloadIssuesList];
            } // for (int j = 0; j < ImageList.count; j++)
        } // for (int xx = 0; xx < imagesArr.count; xx++)
        if(imageDownloadComplete == YES) //0 ImageList
        {
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                    
                    [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } // if (imagesArr.count > 0)
    else
    {
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                
            });
        }
    }
    
    
}


- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    __block Comment *comment = [[Comment alloc] init];
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];

        NSArray *dictArray = [dict objectForKey:@"CommentList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictComment = [dictArray objectAtIndex:i];
            
            NSString *CommentBy = [dictComment valueForKey:@"CommentBy"];
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentId"] intValue]];
            NSString *CommentString = [dictComment valueForKey:@"CommentString"];
            NSNumber *CommentType =  [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictComment valueForKey:@"PostId"] intValue]];
            NSDate *CommentDate = [myDatabase createNSDateWithWcfDateString:[dictComment valueForKey:@"CommentDate"]];

            __block BOOL newCommentSaved = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsComment = [theDb executeQuery:@"select comment_id from comment where comment_id = ?",CommentId];
                
                if([rsComment next] == NO) //does not exist, insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into comment (comment_by, comment_id, comment, comment_type, post_id, comment_on) values (?,?,?,?,?,?)",CommentBy,CommentId,CommentString,CommentType,PostId,CommentDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        NSDate *now = [NSDate date];
                        
                        BOOL upPostUpdatedOn = [theDb executeUpdate:@"update post set updated_on = ? where post_id = ?",now,PostId];
                        
                        if(!upPostUpdatedOn)
                        {
                            *rollback = YES;
                            return;
                        }
                        newCommentSaved = YES;
                    }
                }
            }];
            
            if(newCommentSaved == YES)
            {
                
                if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadChatView" object:nil];
                    
                    [self reloadIssuesList];
                }
            }
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [comment updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];

                comment = nil;

                [self reloadIssuesList];
            }
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadCommentsForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadCommentsForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    __block Comment_noti *comment_noti = [[Comment_noti alloc] init];
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        NSArray *dictArray = [dict objectForKey:@"CommentNotiList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictNoti = [dictArray objectAtIndex:i];
            
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"CommentId"] intValue]];
            NSString *UserId = [dictNoti valueForKey:@"UserId"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"PostId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictNoti valueForKey:@"Status"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                theDb.traceExecution = NO;
                BOOL qIns = [theDb executeUpdate:@"insert into comment_noti(comment_id, user_id, post_id, status) values(?,?,?,?)",CommentId,UserId,PostId,Status];
                
                if(!qIns)
                {
                    *rollback = YES;
                    return;
                }

            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentNotiForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [comment_noti updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];

                comment_noti = nil;
                
                [self reloadIssuesList];
            }
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    __block Blocks *blocks = [[Blocks alloc] init];
    
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if(stop)return;
        
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
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadBlocksForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
                [blocks updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"] forCurrentUser:NO];
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadBlocksForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadBlocksForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - helper methods


- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[jsonDateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    
    NSDate *date =  [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (NSString *)serializedStringDateJson: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}

- (void)notifyLocallyWithMessage:(NSString *)message
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)reloadIssuesList
{
    if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
        });
    }
}


#pragma mark - settings
- (void)downloadUserSettings
{
    [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,inactive_days] parameters:nil   success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = responseObject;
        
        NSNumber *NumberOfInactivityDays = [NSNumber numberWithInt:[[dict valueForKey:@"NumberOfInactivityDays"] intValue]];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rs = [db executeQuery:@"select inactiveDays from settings"];
            
            if([rs next])
            {
                BOOL up = [db executeUpdate:@"update settings set inactiveDays = ?",NumberOfInactivityDays];
                
                if(!up)
                {
                    *rollback = YES;
                    return;
                }
            }
            else
            {
                BOOL ins = [db executeUpdate:@"insert into settings (inactiveDays) values (?)",NumberOfInactivityDays];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

- (void)downloadActionSettings
{
    [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,action_setting] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ActionContainer"];
        
        NSArray *ActionList = [dict objectForKey:@"ActionList"];
        NSArray *ActionSequenceList = [dict objectForKey:@"ActionSequenceList"];
        NSArray *ActionUserGroupMappingList = [dict objectForKey:@"ActionUserGroupMappingList"];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
           
            for (int i = 0; i < ActionList.count; i++) {
                NSDictionary *dict = [ActionList objectAtIndex:i];
                if(i == 0)
                {
                    BOOL del = [db executeUpdate:@"delete from set_actions_list"];
                    
                    if(!del)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                

                BOOL ins = [db executeUpdate:@"insert into set_actions_list (name, value) values (?, ?)",[dict valueForKey:@"Name"],[NSNumber numberWithInt:[[dict valueForKey:@"Value"] intValue]]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
                
            }
            
            
            for (int i = 0; i < ActionSequenceList.count; i++) {
                NSDictionary *dict = [ActionSequenceList objectAtIndex:i];
                
                if(i == 0)
                {
                    BOOL del = [db executeUpdate:@"delete from set_action_sequence"];
                    
                    if(!del)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                

                BOOL ins = [db executeUpdate:@"insert into set_action_sequence (CurrentAction, CurrentActionName, NextAction, NextActionName) values (?, ?, ?, ?)",[NSNumber numberWithInt:[[dict valueForKey:@"CurrentAction"] intValue]], [dict valueForKey:@"CurrentActionName"], [NSNumber numberWithInt:[[dict valueForKey:@"NextAction"] intValue]], [dict valueForKey:@"NextActionName"]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
                
            }
            
            
            for (int i = 0; i < ActionUserGroupMappingList.count; i++) {
                NSDictionary *dict = [ActionUserGroupMappingList objectAtIndex:i];
                
                if( i == 0)
                {
                    BOOL del = [db executeUpdate:@"delete from set_action_group"];
                    
                    if(!del)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
                BOOL ins = [db executeUpdate:@"insert into set_action_group (ActionName, ActionValue, GroupId, GroupName) values (?, ?, ?, ?)",[dict valueForKey:@"ActionName"], [NSNumber numberWithInt:[[dict valueForKey:@"ActionValue"] intValue]], [NSNumber numberWithInt:[[dict valueForKey:@"GroupId"] intValue]], [dict valueForKey:@"GroupName"]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
            
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

- (void)startDownloadContractTypePage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_contract_types] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        /*
         dragons!
         . delete entries of contract_type table and insert a new one. this is done this way to allow currently logged in user to auto update their contract types. once user is logged out, contract_type table is also emptied and a new one will be downloaded.
         */
        if(page == 1) //delete only once
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
        
        
        NSDictionary *dict = [responseObject objectForKey:@"ContractTypeContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ContractTypeList"];
        
        for (int i = 0; i < dictArray.count; i++) {
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
            [self startDownloadContractTypePage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}
@end
