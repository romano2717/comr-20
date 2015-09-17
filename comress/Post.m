//
//  Post.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Post.h"
#import "Synchronize.h"

@implementation Post

@synthesize
client_post_id,
post_id,
post_topic,
post_by,
post_date,
updated_on,
post_type,
severity,
address,
status,
level,
block_id,
postal_code,
seen,
contract_type;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    return self;
}

- (long long)savePostWithDictionary:(NSDictionary *)dict
{
    __block BOOL postSaved;
    __block long long posClienttId = 0;
    
    client_post_id  = [[dict valueForKey:@"client_post_id"] intValue];
    post_id         = [[dict valueForKey:@"post_id"] intValue];
    post_topic      = [dict valueForKey:@"post_topic"];
    post_by         = [dict valueForKey:@"post_by"];
    post_date       = [dict valueForKey:@"post_date"];
    post_type       = [dict valueForKey:@"post_type"];
    severity        = [dict valueForKey:@"severity"];
    address         = [dict valueForKey:@"address"];
    status          = [dict valueForKey:@"status"];
    level           = [dict valueForKey:@"level"];
    block_id        = [dict valueForKey:@"block_id"];
    postal_code     = [dict valueForKey:@"postal_code"];
    updated_on      = [dict valueForKey:@"updated_on"];
    seen            = [dict valueForKey:@"seen"];
    contract_type   = [dict valueForKey:@"contract_type"];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        postSaved = [db executeUpdate:@"insert into post (post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,isUpdated,postal_code,updated_on,seen,contract_type) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,[NSNumber numberWithBool:YES],postal_code,updated_on,seen,contract_type];
        
        if(!postSaved)
        {
            *rollback = YES;
        }
        posClienttId = [db lastInsertRowId];
    }];
    
    return posClienttId;
}


- (long long)savePostWithDictionary:(NSDictionary *)dict forBlockId:(NSNumber *)blockId
{
    __block BOOL postSaved;
    __block long long posClienttId = 0;
    
    client_post_id  = [[dict valueForKey:@"client_post_id"] intValue];
    post_id         = [[dict valueForKey:@"post_id"] intValue];
    post_topic      = [dict valueForKey:@"post_topic"];
    post_by         = [dict valueForKey:@"post_by"];
    post_date       = [dict valueForKey:@"post_date"];
    post_type       = [dict valueForKey:@"post_type"];
    severity        = [dict valueForKey:@"severity"];
    address         = [dict valueForKey:@"address"];
    status          = [dict valueForKey:@"status"];
    level           = [dict valueForKey:@"level"];
    block_id        = [dict valueForKey:@"block_id"];
    postal_code     = [dict valueForKey:@"postal_code"];
    updated_on      = [dict valueForKey:@"updated_on"];
    seen            = [dict valueForKey:@"seen"];
    
    if(block_id == nil)
        return 0;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        NSNumber *postTypeRoutine = [NSNumber numberWithInt:2];
        
        FMResultSet *rs = [db executeQuery:@"select block_id, post_type from post where post_type = ? and block_id = ?",postTypeRoutine, blockId];
        
        if([rs next] == NO) //does not exist, create!
        {
            postSaved = [db executeUpdate:@"insert into post (post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,isUpdated,postal_code,updated_on,seen) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,[NSNumber numberWithBool:YES],postal_code,updated_on,seen];
            
            if(!postSaved)
            {
                *rollback = YES;
            }
            posClienttId = [db lastInsertRowId];
        }
    }];
    
    return posClienttId;
}

- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue fromSurvey:(BOOL)fromSurvey
{
    BOOL POisLoggedIn = YES; //CT_NU uses the same logic as PO
    BOOL PMisLoggedIn = YES;
    
    
    //town council sa, pm and GM function as PM
    
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PM"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SUP"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"GM"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SA"])
    {
        PMisLoggedIn = YES;
        POisLoggedIn = NO;
    }

    
//    @try {
        int __block overDueIssues = 0;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        
        client_post_id      = [[params valueForKey:@"client_post_id"] intValue];
        post_id             = [[params valueForKey:@"post_id"] intValue];
        post_topic          = [params valueForKey:@"post_topic"];
        post_by             = [params valueForKey:@"post_by"];
        post_date           = [params valueForKey:@"post_date"];
        post_type           = [params valueForKey:@"post_type"];
        severity            = [params valueForKey:@"severity"];
        address             = [params valueForKey:@"address"];
        status              = [params valueForKey:@"status"];
        level               = [params valueForKey:@"level"];
        
        /*
         change query to also get all the images for the post
         */
        NSMutableString *q;
        NSMutableString *qOverDue;
        
        NSDate *now = [NSDate date];
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *daysAgo = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:-overDueDays*23*59*59];
        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
        NSNumber *finishedStatus = [NSNumber numberWithInt:4];
    
    
        __block NSNumber *inactiveDays = [NSNumber numberWithInt:3]; //default
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select inactiveDays from settings"];
            while ([rs next]) {
                inactiveDays = [NSNumber numberWithInt:[rs intForColumn:@"inactiveDays"]];
            }
        }];
    
    
    
        if(postId == nil) //for listing
        {
            if(onlyOverDue == NO)
            {
                if(filter == YES) //ME, don't display overdue
                {
                    q = [[NSMutableString alloc] initWithString:@"select * from post where post_type = 1 and block_id in (select block_id from blocks_user)"]; //post_type = 1 is ISSUES
                    
                    qOverDue = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where post_type = 1 and dueDate <= '%f' and status != %@ and block_id in (select block_id from blocks_user) ",timestampDaysAgo, finishedStatus]]; //post_type = 1 is ISSUES
                }
                
                else // Others
                {
                    //q = [[NSMutableString alloc] initWithString:@"select * from post where post_type = 1 " ]; //post_type = 1 is ISSUES
                    q = [[NSMutableString alloc] initWithString:@"select * from post where post_type = 1 and block_id NOT IN (select block_id from blocks_user) "];
                }
            }
            
            else //OVERDUE TAB!
            {
                q = [[NSMutableString alloc] initWithString:@"select * from post where post_type = 1 and block_id in (select block_id from blocks_user)"]; //post_type = 1 is ISSUES
            }
        }
        
        else //for chat or by PM
        {

            q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where client_post_id = %@ ",postId]];
                
            qOverDue = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where client_post_id = %@ and dueDate <= '%f' and status != %@ ",postId,timestampDaysAgo,finishedStatus]];
            
        }
        
        
        if([params valueForKey:@"order"])
        {
            [q appendString:[params valueForKey:@"order"]];
        }
        

        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            db.traceExecution = NO;
            FMResultSet *rsPost = [db executeQuery:q];
            
            while ([rsPost next]) {
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"client_post_id"]];
                NSNumber *serverPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];

                //if the post is Closed and updated_on is more than 3 days ago, skip it
                int thePostStatus = [rsPost intForColumn:@"status"];
                NSDate *theLastUpdatedDate = [rsPost dateForColumn:@"updated_on"];
                NSDate *dueDate = [rsPost dateForColumn:@"dueDate"];
                
                int lastUpdatedDateDiff = [self daysBetween:theLastUpdatedDate and:[NSDate date]];
                int dueDateDateDiff = [self daysBetween:dueDate and:[NSDate date]];

                if(thePostStatus == 4 && lastUpdatedDateDiff >= [inactiveDays intValue] && dueDateDateDiff > 0) //and due date is already past
                {
                    //delete this post
                    BOOL delPost = NO;
                    
                    if([clientPostId intValue] > 0)
                        delPost = [db executeUpdate:@"delete from post where client_post_id = ?",clientPostId];
                    else if ([serverPostId intValue] > 0)
                        delPost = [db executeUpdate:@"delete from post where post_id = ?",serverPostId];
                    
                    continue;
                }
                
                
                //check if the contract_type of this post is other (6), if so, don't add here
                if(filter == YES && [[myDatabase.userDictionary valueForKey:@"group_name"] rangeOfString:@"CT"].location != NSNotFound)
                {
                    int theContractType = [rsPost intForColumn:@"contract_type"];
                    
                    if(theContractType == 6)
                        continue;
                }
                
                
                if(postId == nil)
                {
                    if(onlyOverDue == NO && filter == YES && postId == nil) //ME
                    {
                        //due date
                        NSDate *now = [NSDate date];
                        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                        NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*23*59*59]; //add 3 days, default calculation in-case the post don't have a duedate(offline) mode
                        
                         NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        
                        if([rsPost dateForColumn:@"dueDate"] != nil)
                            dueDate = [rsPost dateForColumn:@"dueDate"];
                        
                        int the_status = [rsPost intForColumn:@"status"];

                        int daysBetween = [self daysBetween:dueDate and:nowAtZeroHour];
                        
                        if(daysBetween >= 1 && the_status != 4) //overdue and not closed, don't add to ME
                            continue;
                    }
                    else if (onlyOverDue == YES && filter == YES && postId == nil) //overdue
                    {
                        //due date
                        NSDate *now = [NSDate date];
                        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                        NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*23*59*59]; //add 3 days, default calculation in-case the post don't have a duedate(offline) mode
                        NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        
                        if([rsPost dateForColumn:@"dueDate"] != nil)
                            dueDate = [rsPost dateForColumn:@"dueDate"];
                        
                        int the_status = [rsPost intForColumn:@"status"];
                        
                        int daysBetween = [self daysBetween:dueDate and:nowAtZeroHour];
                        
                        if(the_status == 4)//closed, don't add to overdue
                            continue;
                        else
                        {
                            if(daysBetween <= 0 && the_status != 4) //not overdue and closed, don't add to OVERDUE
                                continue;
                        }
                    }
                    
                }
                else
                {
                    if(onlyOverDue == NO && filter == YES && postId != nil) //post per PO: when pm is logged in
                    {
                        //due date
                        NSDate *now = [NSDate date];
                        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                        NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*23*59*59]; //add 3 days, default calculation in-case the post don't have a duedate(offline) mode
                        NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        
                        if([rsPost dateForColumn:@"dueDate"] != nil)
                            dueDate = [rsPost dateForColumn:@"dueDate"];
                        
                        int the_status = [rsPost intForColumn:@"status"];
                        
                        int daysBetween = [self daysBetween:dueDate and:nowAtZeroHour];
                        
                        if(daysBetween >= 1 && the_status != 4) //overdue and not closed, don't add to ME
                            continue;
                    }
                }
                
                NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
                
                [postChild setObject:[rsPost resultDictionary] forKey:@"post"];
                
                //change the post_by of this post based on who's PO this block belongs to
                NSMutableDictionary *mutablePostDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPost resultDictionary]];
                
                FMResultSet *rsGetPoOfThisBlock = [db executeQuery:@"select user_id from block_user_mapping where block_id = ?",[NSNumber numberWithInt:[[mutablePostDict valueForKey:@"block_id"] intValue]]];
                
                int multiBlockAssignmentCtr = 0;
                while ([rsGetPoOfThisBlock next]) {
                    if(multiBlockAssignmentCtr == 0)
                        [mutablePostDict setObject:[rsGetPoOfThisBlock stringForColumn:@"user_id"] forKey:@"under_by"];
                    else
                        [mutablePostDict setObject:[rsGetPoOfThisBlock stringForColumn:@"user_id"] forKey:[NSString stringWithFormat:@"under_by%d",multiBlockAssignmentCtr]];
                    
                    multiBlockAssignmentCtr++;
                }
                
                //OTHERS: check if this block is owned by a PO/contractor under the current user's pm/supervisor
//                if(onlyOverDue == NO && filter == NO && fromSurvey == NO && postId == nil)
//                {
//                    
//                    if(POisLoggedIn)
//                    {
//                        db.traceExecution = NO;
//
//                        FMResultSet *rsCheckSupervisor = [db executeQuery:@"select * from block_user_mapping where supervisor_id = (select supervisor_id from block_user_mapping where user_id = ?) and user_id != ? and block_id = ?",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"],[NSNumber numberWithInt:[[mutablePostDict valueForKey:@"block_id"] intValue]]];
//                        
//                        if([rsCheckSupervisor next] == YES)
//                            [postChild setObject:mutablePostDict forKey:@"post"];
//                        else
//                            continue; //don't add
//                    }
//                    else if(PMisLoggedIn)
//                    {
                
//                        FMResultSet *rsCheckSupervisor = [db executeQuery:@"select block_id from block_user_mapping where block_id = ? and supervisor_id != ?",[NSNumber numberWithInt:[[mutablePostDict valueForKey:@"block_id"] intValue]],[myDatabase.userDictionary valueForKey:@"user_id"]];
//                        
//                        if([rsCheckSupervisor next] == YES)
//                            [postChild setObject:mutablePostDict forKey:@"post"];
//                        else
//                            continue;// don't add
//                    }
//                }

//                else
                //the above code is commented since its not a valid situation anymore since a current user's coworkers might have different supervisor
                    [postChild setObject:mutablePostDict forKey:@"post"];
                if(onlyOverDue == YES)
                    overDueIssues ++;
                
                
                //check if this post is not yet read by the user
                NSNumber *newCommentsCount = [NSNumber numberWithInt:0];
                FMResultSet *rsRead = [db executeQuery:@"select count(*) as count from comment_noti where post_id = ? and status = ? group by post_id",serverPostId,[NSNumber numberWithInt:1]];
                if([rsRead next] == YES)
                    newCommentsCount = [NSNumber numberWithInt:[rsRead intForColumn:@"count"]];
                
                [postChild setObject:newCommentsCount forKey:@"newCommentsCount"];
                
                
                
                //add all images of this post
                FMResultSet *rsPostImage;
                
                if([serverPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where post_id = ? order by client_post_image_id ",serverPostId];
                }
                else if([clientPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where client_post_id = ? order by client_post_image_id ",clientPostId];
                }
                
                NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
                
                while ([rsPostImage next]) {
                    [imagesArray addObject:[rsPostImage resultDictionary]];
                }
                
                [postChild setObject:imagesArray forKey:@"postImages"];
                
                
                //get all comments for this post including comment image if there's any
                FMResultSet *rsPostComment = nil;
                
                if([serverPostId intValue] > 0)
                    rsPostComment = [db executeQuery:@"select * from comment where post_id = ? order by comment_on asc",serverPostId];
                else if ([clientPostId intValue] > 0)
                    rsPostComment = [db executeQuery:@"select * from comment where client_post_id = ? order by comment_on asc",clientPostId];
                
                NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
                
                while ([rsPostComment next]) {
                    
                    NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                    
                    if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                    {
                        //get the image path
                        FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]]];
                        
                        while ([rsImagePath next]) {
                            [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                        }
                    }
                    
                    [commentsArray addObject:commentsDict];
                    
                }
                
                [postChild setObject:commentsArray forKey:@"postComments"];
                
                [postDict setObject:postChild forKey:postId ? postId : clientPostId];
                
                [arr addObject:postDict];
            }
            
        }];
        
        NSMutableArray *mutArr = [[NSMutableArray alloc] initWithArray:arr];
        
        //re-order the posts according to unread messages
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from comment_noti where status = ? order by id desc",[NSNumber numberWithInt:1]];
            
            while ([rs next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                
                
                for (int i = 0; i < arr.count; i++) {
                    NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                    NSNumber *key = [[dict allKeys] lastObject];
                    NSNumber *postIdNum = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"];
                    
                    if([postIdNum isEqual:[NSNull null]])
                        return;
                    
                    if([postId intValue] == [postIdNum intValue])
                    {
                        [mutArr removeObject:dict];
                        [mutArr insertObject:dict atIndex:0];
                    }
                }
            }
        }];
        
        //reorder the posts according to new issues
        if(newIssuesFirst)
        {
            for (int i = 0; i < arr.count; i++) {
                NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                NSNumber *key = [[dict allKeys] lastObject];
                NSNumber *seenPost = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"seen"];
                
                if([seenPost intValue] == 0)
                {
                    [mutArr removeObject:dict];
                    [mutArr insertObject:dict atIndex:0];
                }
            }
        }
        
        if(mutArr.count == arr.count)
            return mutArr;
        
        return arr;
//    }
//    @catch (NSException *exception) {
//        DDLogVerbose(@"fetchIssuesWithParams: %@",exception);
//    }
//    @finally {
//
//    }
}

- (NSArray *)fetchIssuesWithParamsForPM:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue
{
    NSMutableString *q;
    NSMutableString *qOverdue;
    
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    comps.hour = 23;
    comps.minute = 59;
    comps.second = 59;

    NSDate *daysAgo = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:-overDueDays*23*59*59];
    double timestampDaysAgo = [daysAgo timeIntervalSince1970] + 0.483;//retain the 0.483 coz existing data in already have 0.483 in date time
    
    NSNumber *finishedStatus = [NSNumber numberWithInt:4];
    
    if(postId == nil)
    {
        if(onlyOverDue == NO)
        {
            if(filter == YES) //ME
            {
                if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"] == NO)
                {
                    //where supervisor_id = '%@ OR user_id = '%@' : some contractor is also the supervisor
                    q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,client_post_id,p.dueDate,p.status,p.updated_on,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@' or user_id = '%@')",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]]];
                    
                    qOverdue = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,p.updated_on,client_post_id,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@') and dueDate <= '%f' and status != %@  ",[myDatabase.userDictionary valueForKey:@"user_id"], timestampDaysAgo, finishedStatus]];
                }
                else //user is ct_sa
                {
                    q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,client_post_id,p.dueDate,p.status,p.updated_on,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping)"]];
                    
                    qOverdue = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,p.updated_on,client_post_id,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping) and dueDate <= '%f' and status != %@  ", timestampDaysAgo, finishedStatus]];
                }
            }
            else //Others
            {
                q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,client_post_id,p.status, p.updated_on, bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id not in (select block_id from blocks_user) and bum.supervisor_id != '%@' ",[myDatabase.userDictionary valueForKey:@"user_id"]]];
            }
        }
        else //overdue
        {
            if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"] == NO)
            {
                 q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,client_post_id,p.updated_on,p.status,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@' or user_id = '%@') and dueDate <= '%f' and status != %@  ",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"], timestampDaysAgo, finishedStatus]];
            }
            else
            {
                 q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select p.post_id,client_post_id,p.updated_on,p.status,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping ) and dueDate <= '%f' and status != %@  ", timestampDaysAgo, finishedStatus]];            
            }
            
        }
    }
    
    if([params valueForKey:@"order"])
    {
        [q appendString:[params valueForKey:@"order"]];
    }
    
    NSMutableArray *postIdArray = [[NSMutableArray alloc] init];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        FMResultSet *rs = [db executeQuery:q];
        
        while ([rs next]) {
            
            NSNumber *theClientPostId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]];
            NSNumber *thePostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSString *POId = [rs stringForColumn:@"user_id"];
            
            if(onlyOverDue == NO && filter == YES && postId == nil)
            {
                //due date
                NSDate *now = [NSDate date];
                NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*23*59*59]; //add 3 days
                
                if([rs dateForColumn:@"dueDate"] != nil)
                    dueDate = [rs dateForColumn:@"dueDate"];
                
                int the_status = [rs intForColumn:@"status"];
                
                int daysBetween = [self daysBetween:dueDate and:[NSDate date]];
                
                if(daysBetween > 3 && the_status != 4) //overdue and not closed, don't add to ME
                    continue;
            }
            
            //if the post is Closed and updated_on is more than 3 days ago, skip it
            int thePostStatus = [rs intForColumn:@"status"];
            NSDate *theLastUpdatedDate = [rs dateForColumn:@"updated_on"];
            
            int lastUpdatedDateDiff = [self daysBetween:theLastUpdatedDate and:[NSDate date]];
            if(thePostStatus == 4 && lastUpdatedDateDiff >= 3)
                continue;
            
            [postIdArray addObject:@{@"clientPostId":theClientPostId,@"postId":thePostId,@"POId":POId}];
        }
    }];
    
    NSMutableArray *postArray = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < postIdArray.count; i++)
    {
        NSDictionary *dict = [postIdArray objectAtIndex:i];
        
        NSNumber *clientPostId = [dict valueForKey:@"clientPostId"];
        NSString *POId = [dict valueForKey:@"POId"];

        if(filter == YES)
        {
            NSArray *post = [self fetchIssuesWithParams:params forPostId:clientPostId filterByBlock:filter newIssuesFirst:NO onlyOverDue:onlyOverDue fromSurvey:NO];

            if(post.count > 0)
                [postArray addObject:[post firstObject]];
        }
        
        else
        {
            
            //get the count of posts of this po
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                db.traceExecution = NO;
                FMResultSet *rsPostCount = [db executeQuery:@"select count(*)as count,bum.division,p.post_id from post p left join block_user_mapping bum on p.block_id=bum.block_id where bum.user_id = ?",POId];
                
                //count how many unread post under this po
                int unreadPostCount = 0;
                
                NSPredicate *filter = [NSPredicate predicateWithFormat:@"POId = %@", POId];
                NSArray *filteredDict = [postIdArray filteredArrayUsingPredicate:filter];
                NSArray *filterPostIdArr = [filteredDict valueForKeyPath:@"postId"];
                
                NSMutableArray *postIdNsNumberArr = [[NSMutableArray alloc] init];
                for (int x = 0; x < filterPostIdArr.count; x++) {
                    [postIdNsNumberArr addObject:[NSNumber numberWithInt:[[filterPostIdArr objectAtIndex:x] intValue]]];
                }
                
                NSString *stringPostIdArray = [filterPostIdArr componentsJoinedByString:@","];
                
                NSString *qqq = [NSString stringWithFormat:@"select * from comment_noti where post_id in (%@) and status = %@",stringPostIdArray,[NSNumber numberWithInt:1]];
            
                FMResultSet *unreadPostRs = [db executeQuery:qqq];

                
                while ([unreadPostRs next]) {
                    unreadPostCount++;
                }
                
                while ([rsPostCount next]) {
                    NSDictionary *dict = @{@"po":POId,@"count":[NSNumber numberWithInt:[rsPostCount intForColumn:@"count"]],@"division":[rsPostCount stringForColumn:@"division"],@"unreadPost":[NSNumber numberWithInt:unreadPostCount]};
                    
                    [postArray addObject:dict];
                }
            }];
            
            
        }
    }
    return postArray;
}


- (NSArray *)fetchIssuesWithParamsForPMOthers:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue
{
    /*
     
     . get a list of all divisions
     . get all users under per division
     . count how many posts belong to this user under this division
     
     */
    
    NSMutableArray *groupedUserPerDiv = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSMutableArray *divisionArray = [[NSMutableArray alloc] init];
        
        NSString *userIdString = [NSString stringWithFormat:@"%@",[[myDatabase.userDictionary valueForKey:@"user_id"] lowercaseString]];
        
        FMResultSet *rsGetDiv = [db executeQuery:@"select division from block_user_mapping where lower(supervisor_id) != ? and lower(user_id) != ? group by division",userIdString,userIdString];

        while ([rsGetDiv next]) {
            [divisionArray addObject:[rsGetDiv stringForColumn:@"division"]];
        }
        
        
        for (int i = 0; i < divisionArray.count; i++) {

            FMResultSet *rsGetUsers = [db executeQuery:@"select lower(user_id) as user_id from block_user_mapping where division = ? and lower(supervisor_id) != ? and lower(user_id) != ? group by user_id",[divisionArray objectAtIndex:i],userIdString,userIdString];

            NSMutableArray *usersArray = [[NSMutableArray alloc] init];
            
            while ([rsGetUsers next]) {
                
                NSString *userId = [[rsGetUsers stringForColumn:@"user_id"] lowercaseString];
                
                //count how many post belong to this user under this division
                FMResultSet *rsPostCount = [db executeQuery:@"select count(*) as count from post p left join block_user_mapping bum on p.block_id=bum.block_id where lower(bum.user_id) = ? and bum.division = ?",userId,[divisionArray objectAtIndex:i]];
                
                int postCount = 0;
                int unreadPostCount = 0;
                
                while ([rsPostCount next]) {
                    postCount = [rsPostCount intForColumn:@"count"];
                }
                
                //count how many unread post for this user
                FMResultSet *rsUnreadPostCount = [db executeQuery:@"select count(*)as count from comment_noti where post_id in(select post_id from post p left join block_user_mapping bum on p.block_id=bum.block_id where lower(bum.user_id) = ?) and status = ?",userId,[NSNumber numberWithInt:1]];
                while ([rsUnreadPostCount next]) {
                    unreadPostCount = [rsUnreadPostCount intForColumn:@"count"];
                }
                
                NSDictionary *userDictInfo = @{@"user":userId,@"count":[NSNumber numberWithInt:postCount],@"unreadPost":[NSNumber numberWithInt:unreadPostCount],@"division":[divisionArray objectAtIndex:i]};
                
                if(postCount > 0 && [usersArray containsObject:userDictInfo] == NO)
                    [usersArray addObject:userDictInfo];
            }
            
            [groupedUserPerDiv addObject:@{@"division":[divisionArray objectAtIndex:i],@"users":usersArray}];
        }
    }];
    
    return groupedUserPerDiv;
}

- (NSArray *)fetchIssuesForCurrentUser
{
    NSMutableArray *postArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *postIdArray = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *userIdString = [[NSString stringWithFormat:@"%@",[myDatabase.userDictionary valueForKey:@"user_id"]] lowercaseString];
        
        FMResultSet *rs = [db executeQuery:@"select client_post_id,post_id from post where lower(post_by) = ? order by updated_on desc",userIdString];
        
        while ([rs next]) {
            [postIdArray addObject:[NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]]];
        }
    }];
    
    NSDictionary *params = @{@"order":@"order by updated_on desc"};

    for (int i = 0; i < postIdArray.count; i++) {
        
        NSNumber *clientPostId = [postIdArray objectAtIndex:i];

        NSArray *post = [self fetchIssuesWithParams:params forPostId:clientPostId filterByBlock:NO newIssuesFirst:NO onlyOverDue:NO fromSurvey:NO];
        
        if(post.count > 0)
            [postArray addObject:[post firstObject]];
    }
    return postArray;
}

- (NSArray *)fetchIssuesForPO:(NSString *)poID division:(NSString *)division
{
    NSDictionary *params = @{@"order":@"order by updated_on desc"};
    
    NSMutableArray *postArray = [[NSMutableArray alloc] init];
    NSMutableArray *postIdArray = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select p.client_post_id from post p left join block_user_mapping bum on p.block_id = bum.block_id where lower(bum.user_id) = ? and bum.division = ? order by p.updated_on desc",poID,division];
        
       
        while ([rs next]) {
            NSNumber *thePostId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]];
            
            [postIdArray addObject:thePostId];
        }
    }];
    
    for (int i = 0; i < postIdArray.count; i++) {
        
        NSNumber *thePostId = [postIdArray objectAtIndex:i];
        
        NSArray *post = [self fetchIssuesWithParams:params forPostId:thePostId filterByBlock:NO newIssuesFirst:YES onlyOverDue:NO fromSurvey:NO ];
        
        if(post.count > 0)
            [postArray addObject:[post firstObject]];
    }
    
    return postArray;
}

- (NSArray *)postsToSend
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
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
                                   @"IsUpdated":[NSNumber numberWithBool:NO]
                                   };
            
            
            [rsArray addObject:dict];
            
            dict = nil;
        }
        
        [db close];
    }];
    
    return nil;
}

- (BOOL)updatePostStatusForClientPostId:(NSNumber *)clientPostId withStatus:(NSNumber *)theStatus
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        BOOL upPost = [theDb executeUpdate:@"update post set status = ? where client_post_id = ?",theStatus,clientPostId];
        
        if(!upPost)
        {
            *rollback = YES;
            return ;
        }
        
        BOOL postWasUpdated = [theDb executeUpdate:@"update post set statusWasUpdated = ? where client_post_id = ?",[NSNumber numberWithBool:YES],clientPostId];
        
        if(!postWasUpdated)
        {
            *rollback = YES;
            return;
        }
    }];
    
    Synchronize *sync = [Synchronize sharedManager];
    [sync uploadPostStatusChangeFromSelf:NO];
    
    return YES;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from post_last_request_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into post_last_request_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update post_last_request_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

- (BOOL)updatePostAsSeen:(NSNumber *)clientPostId serverPostId:(NSNumber *)serverPostId
{
    __block BOOL ok = YES;
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    myDatabase = [Database sharedMyDbManager];
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        //update this post as seen
        NSNumber *wasSeen = [NSNumber numberWithBool:YES];

        BOOL postSeen = [db executeUpdate:@"update post set seen = ? where client_post_id = ?", wasSeen,clientPostId];
        if(!postSeen)
        {
            ok = NO;
            *rollback = YES;
            return;
        }
        
        //set status = 2 of this post from comment noti
        BOOL rmNoti = [db executeUpdate:@"update comment_noti set status = ? where post_id = ? and post_id != ?",[NSNumber numberWithInt:2],serverPostId,zero];
        
        if(!rmNoti)
        {
            ok = NO;
            *rollback = YES;
            return;
        }
    }];
    
    Synchronize *sync = [Synchronize sharedManager];
    
    [sync uploadCommentNotiAlreadyReadFromSelf:NO];

    [sync updatePostAsSeenForPostId:serverPostId];
    
    return ok;
}


#pragma mark - routine posts

-(NSArray *)fetchPostsForBlockId:(NSNumber *)blockId
{
    @try {
        //myDatabase.allPostWasSeen = YES;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        
        /*
         change query to also get all the images for the post
         */


        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsPost = [db executeQuery:@"select * from post where block_id = ? and post_type = ?",blockId,[NSNumber numberWithInt:2]];
            
            while ([rsPost next]) {
                
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"client_post_id"]];
                NSNumber *serverPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
                
                NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
                
                
                //if([rsPost boolForColumn:@"seen"] == NO) //if we found at leas one we flag it to no
                  //  myDatabase.allPostWasSeen = NO;
                
                [postChild setObject:[rsPost resultDictionary] forKey:@"post"];
                
                
                //check if this post is not yet read by the user
                NSNumber *newCommentsCount = [NSNumber numberWithInt:0];
                FMResultSet *rsRead = [db executeQuery:@"select count(*) as count from comment_noti where post_id = ? and status = ? group by post_id",serverPostId,[NSNumber numberWithInt:1]];
                if([rsRead next] == YES)
                    newCommentsCount = [NSNumber numberWithInt:[rsRead intForColumn:@"count"]];
                
                [postChild setObject:newCommentsCount forKey:@"newCommentsCount"];
                
                
                //add all images of this post
                FMResultSet *rsPostImage;
                
                if([serverPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where post_id = ? order by client_post_image_id ",serverPostId];
                }
                else if([clientPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where client_post_id = ? order by client_post_image_id ",clientPostId];
                }
                
                NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
                
                while ([rsPostImage next]) {
                    [imagesArray addObject:[rsPostImage resultDictionary]];
                }
                
                [postChild setObject:imagesArray forKey:@"postImages"];
                
                
                //get all comments for this post including comment image if there's any
                FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where (client_post_id = ? or post_id = ?)  order by comment_on desc",clientPostId,serverPostId];
                NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
                
                while ([rsPostComment next]) {
                    
                    NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                    
                    if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                    {
                        //get the image path
                        FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]]];
                        
                        while ([rsImagePath next]) {
                            [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                        }
                    }
                    
                    [commentsArray addObject:commentsDict];
                    
                }
                
                [postChild setObject:commentsArray forKey:@"postComments"];
                
                [postDict setObject:postChild forKey:blockId ? blockId : clientPostId];
                
                [arr addObject:postDict];
            }
        }];
        
        NSMutableArray *mutArr = [[NSMutableArray alloc] initWithArray:arr];
        
        //re-order the posts according to unread messages
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from comment_noti order by id desc"];
            
            while ([rs next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                
                for (int i = 0; i < arr.count; i++) {
                    NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                    NSNumber *key = [[dict allKeys] lastObject];
                    NSNumber *postIdNum = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"];
                    
                    if([postIdNum isEqual:[NSNull null]])
                        return;
                    
                    if([postId intValue] == [postIdNum intValue])
                    {
                        [mutArr removeObject:dict];
                        [mutArr insertObject:dict atIndex:0];
                    }
                }
            }
        }];
        
        if(mutArr.count == arr.count)
            return mutArr;
        
        //if(myDatabase.allPostWasSeen)
        //{
           // [[NSNotificationCenter defaultCenter] postNotificationName:@"allPostWasSeen" object:nil];
        //}
        
        return arr;
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"fetchIssuesWithParams: %@",exception);
    }
    @finally {
        
    }
}

- (NSArray *)searchPostWithKeyword:(NSString *)keyword
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select p.post_id, p.client_post_id, p.post_topic, p.address, p.postal_code, p.post_by, c.comment from post p left join comment c on (p.post_id = c.post_id or p.client_post_id = c.client_post_id) where p.post_topic like '%?%' or p.address like '%?%' or p.postal_code like '%?%' or p.post_by like '%?%' or c.comment like '%?%' group by p.post_id",keyword,keyword,keyword,keyword,keyword];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    

    
    return nil;
}

- (BOOL)setIssueCloseActionRemarks:(NSDictionary *)dict
{
    __block BOOL flag = NO;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *actions_done = [[dict objectForKey:@"actions"] valueForKey:@"actionsTaken"];
        NSString *remarks = [[dict objectForKey:@"actions"] valueForKey:@"remarks"];
        NSNumber *thePostId = [NSNumber numberWithInt:[[dict valueForKey:@"post_id"] intValue]];
        NSNumber *clientPostId = [NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]];
        
        flag = [db executeUpdate:@"insert into post_close_issue_remarks (actions_taken,remarks,post_id,client_post_id) values (?,?,?,?)",actions_done,remarks,thePostId,clientPostId];
       
        if(!flag)
        {
            *rollback = YES;
            return;
        }
    }];
    
    return flag;
}

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return (int)[components day]+1;
}


- (NSArray *)postLIstForSegment:(NSString *)segment forUserType:(NSString *)userType
{
    //this code block only apply for PO and similar PO functionality
    
    NSMutableArray *postArray = [[NSMutableArray alloc] init];
    NSString *query;
    
    //date mgmt
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];

    NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
    double timestampnowAtZeroHour = [nowAtZeroHour timeIntervalSince1970];
    
    NSNumber *closedStatus = [NSNumber numberWithInt:4];
    
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    if([segment isEqualToString:@"ME"])
    {
        
        query = [NSString stringWithFormat:@"select p.*, \
                 bum.user_id as under_by\
                 from \
                 post p \
                 left join block_user_mapping bum \
                 on p.block_id = bum.block_id \
                 where \
                 p.post_type = 1  and \
                 p.block_id in (select block_id from blocks_user) \
                 order by p.updated_on desc"];
        
    }
    
    else if ([segment isEqualToString:@"OTHERS"])
    {
        query = [NSString stringWithFormat:@"select p.*, \
                 bum.user_id as under_by\
                 from \
                 post p \
                 left join block_user_mapping bum \
                 on p.block_id = bum.block_id \
                 where \
                 p.post_type = 1 and \
                 p.block_id not in (select block_id from blocks_user) \
                 order by p.updated_on desc"];
    }
    
    else if([segment isEqualToString:@"OVERDUE"])
    {
        
        query = [NSString stringWithFormat:@"\
                 select p.*, bum.user_id \
                 from post p \
                 left join block_user_mapping bum \
                 on bum.block_id = p.block_id \
                 where p.post_type = 1 and \
                 p.block_id in (select block_id from blocks_user) and \
                 p.dueDate <= %f and \
                 p.status != %@",timestampnowAtZeroHour,closedStatus];
        
    }
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:query];
        
        while ([rs next]) {
            
            //skip post that is closed and no activities for 3 days
            if([segment isEqualToString:@"ME"] || [segment isEqualToString:@"OTHERS"]) //purge only under ME and OTHERS
            {
                int thePostStatus = [rs intForColumn:@"status"];
                NSDate *theLastUpdatedDate = [rs dateForColumn:@"updated_on"];
                
                int lastUpdatedDateDiff = [self daysBetween:theLastUpdatedDate and:[NSDate date]];
                if(thePostStatus == 4 && lastUpdatedDateDiff >= 3)
                    continue;
            }
            
            NSNumber *clientPostId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]];
            NSNumber *serverPostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            
            NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
            
            
            //get post
            [postChild setObject:[rs resultDictionary] forKey:@"post"];
            
            
            //get all comments for this post including comment image if there's any
            FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where (client_post_id = ? or post_id = ?) and post_id != ?  order by comment_on asc",clientPostId,serverPostId,zero];
            NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
            
            while ([rsPostComment next]) {
                
                NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                
                if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                {
                    //get the image path
                    FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ? and comment_id != ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]],zero];
                    
                    while ([rsImagePath next]) {
                        [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                    }
                }
                
                [commentsArray addObject:commentsDict];
                
            }
            [postChild setObject:commentsArray forKey:@"postComments"];
            
            
            
            //add all images of this post
            FMResultSet *rsPostImage = [db executeQuery:@"select * from post_image where (client_post_id = ? or post_id = ?) and post_id != ? order by client_post_image_id",clientPostId,serverPostId,zero];
            
            NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
            
            while ([rsPostImage next]) {
                [imagesArray addObject:[rsPostImage resultDictionary]];
            }
            
            [postChild setObject:imagesArray forKey:@"postImages"];
            
            
            
            //check if this post is not yet read by the user
            NSNumber *newCommentsCount = [NSNumber numberWithInt:0];
            FMResultSet *rsRead = [db executeQuery:@"select count(*) as count from comment_noti where post_id = ? and status = ? group by post_id",serverPostId,[NSNumber numberWithInt:1]];
            if([rsRead next] == YES)
                newCommentsCount = [NSNumber numberWithInt:[rsRead intForColumn:@"count"]];
            
            [postChild setObject:newCommentsCount forKey:@"newCommentsCount"];
            
            
            
            
            
            
            
            //save post dictionary !
            [postArray addObject:postChild];
        }
    }];
    
    return postArray;
}


- (NSArray *)postListForPMForSegment:(NSString *)segment
{
    NSMutableArray *postArray = [[NSMutableArray alloc] init];
    NSString *query;
    
    //date mgmt
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    
    NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
    double timestampnowAtZeroHour = [nowAtZeroHour timeIntervalSince1970];
    
    NSNumber *closedStatus = [NSNumber numberWithInt:4];
    
    
    if([segment isEqualToString:@"ME"])
    {
        query = [NSString stringWithFormat:@"select p.post_id,client_post_id,p.dueDate,p.status, bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@' or user_id = '%@')",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]];
    }
    else if ([segment isEqualToString:@"OTHERS"])
    {
        query = [NSString stringWithFormat:@"select p.post_id,client_post_id,p.status, p.updated_on, bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id not in (select block_id from blocks_user) and bum.supervisor_id != '%@' ",[myDatabase.userDictionary valueForKey:@"user_id"]];
    }
    else if([segment isEqualToString:@"OVERDUE"])
    {
        query = [NSString stringWithFormat:@"select p.post_id,client_post_id,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@' or user_id = '%@') and dueDate <= '%f' and status != %@  ",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"], timestampnowAtZeroHour, closedStatus];
    }
    
    NSMutableArray *foundPostIdArray = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:query];
        
        while ([rs next]) {
            NSNumber *theClientPostId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]];
            NSNumber *thePostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSString *POId = [rs stringForColumn:@"user_id"];
            
            
            if([segment isEqualToString:@"ME"]) //don't display overdue
            {
                //if the post is Closed and updated_on is more than 3 days ago, skip it
                int thePostStatus = [rs intForColumn:@"status"];
                NSDate *theLastUpdatedDate = [rs dateForColumn:@"updated_on"];
                
                int lastUpdatedDateDiff = [self daysBetween:theLastUpdatedDate and:[NSDate date]];
                if(thePostStatus == 4 && lastUpdatedDateDiff >= 3)
                    continue;
                
                
                //due date
                NSDate *now = [NSDate date];
                NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*24*60*60]; //add 3 days
                
                if([rs dateForColumn:@"dueDate"] != nil)
                    dueDate = [rs dateForColumn:@"dueDate"];
                
                int the_status = [rs intForColumn:@"status"];
                
                int daysBetween = [self daysBetween:dueDate and:[NSDate date]];
                
                if(daysBetween > 3 && the_status != 4) //overdue and not closed, don't add to ME
                    continue;
                
                //finally add the post id
                [foundPostIdArray addObject:@{@"clientPostId":theClientPostId,@"postId":thePostId,@"POId":POId}];
            }
        }
    }];
    
    
    //now get the post informatio using foundPostIdArray
    for (int i = 0; i < foundPostIdArray.count; i++) {
        NSDictionary *dict = [foundPostIdArray objectAtIndex:i];
        
        NSNumber *clientPostId = [dict valueForKey:@"clientPostId"];
        NSNumber *serverPostId = [dict valueForKey:@"post_id"];
        NSString *POId = [dict valueForKey:@"POId"];
        
        if([segment isEqualToString:@"ME"])
        {
            NSDictionary *dict = [self postInfoForPostId:serverPostId clientPostId:clientPostId];
            
            if(dict != nil)
                [postArray addObject:dict];
        }
    }
    
    
    return postArray;
}

- (NSDictionary *)postInfoForPostId:(NSNumber *)serverPostId clientPostId:(NSNumber *)clientPostId
{
    NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from post where post_id = ? or client_post_id = ?",serverPostId,clientPostId];
        
        while ([rs next]) {
            //get post
            [postChild setObject:[rs resultDictionary] forKey:@"post"];
            
            
            //get all comments for this post including comment image if there's any
            FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where (client_post_id = ? or post_id = ?)  order by comment_on asc",clientPostId,serverPostId];
            NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
            
            while ([rsPostComment next]) {
                
                NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                
                if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                {
                    //get the image path
                    FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]]];
                    
                    while ([rsImagePath next]) {
                        [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                    }
                }
                
                [commentsArray addObject:commentsDict];
                
            }
            [postChild setObject:commentsArray forKey:@"postComments"];
            
            
            
            //add all images of this post
            FMResultSet *rsPostImage = [db executeQuery:@"select * from post_image where (client_post_id = ? or post_id = ?) order by client_post_image_id",clientPostId,serverPostId];
            
            NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
            
            while ([rsPostImage next]) {
                [imagesArray addObject:[rsPostImage resultDictionary]];
            }
            
            [postChild setObject:imagesArray forKey:@"postImages"];
        }
    }];
    
    return postChild;
}

- (NSArray *)getActionList
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from set_actions_list"];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
        
    }];
    
    return arr;
}

- (NSArray *)getActionSequenceForCurrentAction:(int)currentAction
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from set_action_sequence where CurrentAction = ?",[NSNumber numberWithInt:currentAction]];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}


- (NSArray *)getAvailableActions
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from set_action_group where GroupId = ?",[myDatabase.userDictionary valueForKey:@"group_id"]];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}


- (NSDictionary *)getActionDescriptionForStatus:(int)theStatus
{
    __block NSDictionary *dict = nil;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from set_actions_list where value = ?",[NSNumber numberWithInt:theStatus]];
        
        while ([rs next]) {
            dict = [rs resultDictionary];
        }
    }];
    
    return dict;
}











@end
