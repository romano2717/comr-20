//
//  Survey.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Survey.h"

@implementation Survey

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchSurveyForSegment2:(int)segment
{
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    __block BOOL atleastOneOverdueWasFound = NO;
    __block int overdueCtr = 0;
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ?",clientSurveyId,surveyId];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?)",clientFeedBackId,feedBackId,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*23*59*59];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970] + 0.483;//retain the 0.483 coz existing data in already have 0.483 in date time;
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ?",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4]];
                        
                        if([rsCheckPost next])
                        {
                            atleastOneOverdueWasFound = YES;
                            overdueCtr++;
                        }
                        
                    }
                }
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    //count how many issues this survey have
                    NSNumber *issuesCount = [NSNumber numberWithInt:0];
                    FMResultSet *rsCountPost = [db executeQuery:@"select count(*) as count from post p \
                                              left join su_feedback_issue sf on sf.post_id = p.post_id or sf.client_post_id = p.client_post_id \
                                              left join su_feedback f on sf.feedback_id = f.feedback_id or sf.client_feedback_id = f.client_feedback_id \
                                              left join su_survey s on f.survey_id = s.survey_id or f.client_survey_id = s.client_survey_id \
                                              where (s.client_survey_id = ? or s.survey_id = ?)",clientSurveyId,surveyId];
                    while ([rsCountPost next]) {
                        issuesCount = [NSNumber numberWithInt:[rsCountPost intForColumn:@"count"]];
                    }
                    
                    [row setObject:issuesCount forKey:@"issuesCount"];
                    
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    //don't add overdue survey!
                    if(atleastOneOverdueWasFound == NO)
                    {
                        [row setObject:[NSNumber numberWithBool:NO] forKey:@"overdue"];
                        [surveyArr addObject:row];
                    }
                    else
                        [row setObject:[NSNumber numberWithBool:YES] forKey:@"overdue"];
                    
                }
            }
        }];
        
        DDLogVerbose(@"OD %d",overdueCtr);
    }
    else if (segment == 1)
    {
        NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetSurvey = [db executeQuery:@"select created_by,client_survey_id,survey_id from su_survey where created_by in (select user_id from block_user_mapping where user_id != ?) order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rsGetSurvey next]) {
                
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    NSNumber *clientSurveyId = [NSNumber numberWithInt:[rsGetSurvey intForColumn:@"client_survey_id"]];
                    NSNumber *surveyId = [NSNumber numberWithInt:[rsGetSurvey intForColumn:@"survey_id"]];
                    
//                    //count how many issues this survey have
//                    NSNumber *issuesCount = [NSNumber numberWithInt:0];
//                    
//                    FMResultSet *rsCountPost = [db executeQuery:@"select count(*) as count from post p \
//                                                left join su_feedback_issue sf on sf.post_id = p.post_id or sf.client_post_id = p.client_post_id \
//                                                left join su_feedback f on sf.feedback_id = f.feedback_id or sf.client_feedback_id = f.client_feedback_id \
//                                                left join su_survey s on f.survey_id = s.survey_id or f.client_survey_id = s.client_survey_id \
//                                                where (s.client_survey_id = ? or s.survey_id = ?)",clientSurveyId,surveyId];
//                    while ([rsCountPost next]) {
//                        issuesCount = [NSNumber numberWithInt:[rsCountPost intForColumn:@"count"]];
//                    }
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
//                        [row setObject:issuesCount forKey:@"issuesCount"];

                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                            continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",clientAddressId,addressId];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    
                    if([surveyArr containsObject:groupedDict] == NO)
                        [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        return surveyArr;
    }
    else
    {
        __block BOOL atleastOneOverdueWasFound = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];

                
                if([clientSurveyId intValue] == 0 && [surveyId intValue] == 0)
                    continue;
                
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? ",clientSurveyId,surveyId];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    if([feedBackId intValue] == 0 && [clientFeedBackId intValue] == 0)
                        continue;
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?)",clientFeedBackId,feedBackId,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        if([client_post_id intValue] == 0 && [post_id intValue] == 0)
                            continue;
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*23*59*59];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970] + 0.483;//retain the 0.483 coz existing data in already have 0.483 in date time
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ?",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4]];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ? ",clientSurveyId,surveyId];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    //count how many issues this survey have
                    NSNumber *issuesCount = [NSNumber numberWithInt:0];
                    FMResultSet *rsCountPost = [db executeQuery:@"select count(*) as count from post p \
                                                left join su_feedback_issue sf on sf.post_id = p.post_id or sf.client_post_id = p.client_post_id \
                                                left join su_feedback f on sf.feedback_id = f.feedback_id or sf.client_feedback_id = f.client_feedback_id \
                                                left join su_survey s on f.survey_id = s.survey_id or f.client_survey_id = s.client_survey_id \
                                                where (s.client_survey_id = ? or s.survey_id = ?)",clientSurveyId,surveyId];
                    while ([rsCountPost next]) {
                        issuesCount = [NSNumber numberWithInt:[rsCountPost intForColumn:@"count"]];
                    }
                    
                    [row setObject:issuesCount forKey:@"issuesCount"];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                        continue;
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",clientAddressId,addressId];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    if(atleastOneOverdueWasFound == YES)
                    {
                        [surveyArr addObject:row];
                    }
                }
            }
        }];
    }
    
    return surveyArr;
}

- (NSArray *)fetchSurveyForSegmentForPM:(int)segment
{
    __block NSString *currentUser = [myDatabase.userDictionary valueForKey:@"user_id"];
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
    
    if(segment == 0 || segment == 2)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            NSNumber *numberOfInActiveDays = [NSNumber numberWithInt:3]; //default
            
            FMResultSet *rsGetInactiveDays = [db executeQuery:@"select inactiveDays from settings"];
            
            while ([rsGetInactiveDays next]) {
                numberOfInActiveDays = [NSNumber numberWithInt:[rsGetInactiveDays intForColumn:@"inactiveDays"]];
            }
            
            //FMResultSet *rsGetSurvey = [db executeQuery:@"select * from su_survey where created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) or created_by = ? order by survey_date desc",currentUser,currentUser,currentUser];
            
            NSDate *now = [NSDate date];
            NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
            comps.hour = 23;
            comps.minute = 59;
            comps.second = 59;
            NSDate *daysAgo = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:-[numberOfInActiveDays intValue]*23*59*59];
            NSDate *nowDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
            
            double nowTimestamp = [nowDate timeIntervalSince1970];
            double timestampDaysAgo = [daysAgo timeIntervalSince1970];
            db.traceExecution = NO;
//            FMResultSet *rsGetSurvey = [db executeQuery:@"select s.* from su_survey s left join su_feedback f on s.survey_id = f.survey_id left join su_feedback_issue fs on f.feedback_id = fs.feedback_id left join post p on fs.post_id = p.post_id where((fs.feedback_issue_id is null and s.survey_date > ?) or(fs.feedback_issue_id is not null and fs.post_id = 0 and fs.status = 4 and fs.updated_on > ?)) or (fs.feedback_issue_id is not null and fs.post_id > 0 and (p.status = 4 and p.dueDate > ?)) and s.created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) group by s.survey_id",[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:nowTimestamp],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]];
            FMResultSet *rsGetSurvey = [db executeQuery:@"select s.* from su_survey s left join su_feedback f on s.survey_id = f.survey_id left join su_feedback_issue fs on f.feedback_id = fs.feedback_id left join post p on fs.post_id = p.post_id where s.survey_date > ? and (s.created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) or s.created_by = ? ) group by s.survey_id  order by s.survey_date desc",[NSNumber numberWithDouble:timestampDaysAgo],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            if(segment == 2)
            {
                db.traceExecution = NO;
//                rsGetSurvey = [db executeQuery:@"select s.* from su_survey s left join su_feedback f on s.survey_id = f.survey_id left join su_feedback_issue fs on f.feedback_id = fs.feedback_id left join post p on fs.post_id = p.post_id where((fs.feedback_issue_id is null and s.survey_date < ?) or (fs.feedback_issue_id is not null and fs.post_id = 0 and (fs.status <> 4 or  fs.updated_on < ? )) or (fs.feedback_issue_id is not null and fs.post_id > 0 and p.status <> 4 or p.dueDate <? ))and s.created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) group by s.survey_id",[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:nowTimestamp],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]];
                
                rsGetSurvey = [db executeQuery:@"select s.* from su_survey s left join su_feedback f on s.survey_id = f.survey_id left join su_feedback_issue fs on f.feedback_id = fs.feedback_id left join post p on fs.post_id = p.post_id where s.survey_date < ? and (s.created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) or s.created_by = ? ) group by s.survey_id  order by s.survey_date desc",[NSNumber numberWithDouble:timestampDaysAgo],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"]];
            }
            
            
            while ([rsGetSurvey next]) {
                
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        //if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                          //  continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and (client_address_id <> ? or address_id <> ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    
                    if([surveyArr containsObject:groupedDict] == NO)
                        [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        return surveyArr;
    }
    else if (segment == 1)
    {
        NSMutableArray *surveyPerDivArrayTemp = [[NSMutableArray alloc] init];

        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey su left join block_user_mapping bum on lower(su.created_by) = lower(bum.user_id) where lower(created_by) in (select lower(user_id) from block_user_mapping where supervisor_id != ? group by user_id) group by su.created_by order by survey_date desc;",currentUser];
            
            while ([rs next]) {
                
                NSString *division = [rs stringForColumn:@"division"];
                NSString *createdBy = [rs stringForColumn:@"created_by"];
                
                //count how many survey belong to this user
                int count = 0;
                FMResultSet *rsCount = [db executeQuery:@"select count(*) as count from su_survey where created_by = ?",createdBy];
                while ([rsCount next]) {
                    count = [rsCount intForColumn:@"count"];
                }
                
                NSDictionary *rowDictUsers = @{@"createdBy":createdBy,@"count":[NSNumber numberWithInt:count],@"division":division};
                
                [surveyPerDivArrayTemp addObject:rowDictUsers];
            }
        }];
        
        //group result
        
        NSMutableArray *sectionHeadersMut = [[NSMutableArray alloc] init];
        NSArray *sectionHeaders;
        
        for (int i = 0; i < surveyPerDivArrayTemp.count; i++) {
            NSDictionary *top = (NSDictionary *)[surveyPerDivArrayTemp objectAtIndex:i];
            
            NSString *division = [top valueForKey:@"division"];
            
            [sectionHeadersMut addObject:division];
        }

        //remove dupes of sections
        NSArray *cleanSectionHeadersArray = [[NSOrderedSet orderedSetWithArray:sectionHeadersMut] array];
        
        sectionHeaders = nil;
        sectionHeaders = cleanSectionHeadersArray;
        
        NSMutableArray *groupedPost = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < cleanSectionHeadersArray.count; i++) {
            
            NSString *section = [cleanSectionHeadersArray objectAtIndex:i];
            
            NSMutableArray *row = [[NSMutableArray alloc] init];
            
            for (int j = 0; j < surveyPerDivArrayTemp.count; j++) {
                
                NSDictionary *top = (NSDictionary *)[surveyPerDivArrayTemp objectAtIndex:j];
                
                NSString *division = [top valueForKey:@"division"];
                
                if([division isEqualToString:section])
                {
                    if([row containsObject:top] == NO)
                        [row addObject:top];
                }
            }
            [groupedPost addObject:row];
        }
        
        return groupedPost;
    }
    
    return nil;
}

- (NSArray *)surveyForPo:(NSString *)userId
{
    NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        
        FMResultSet *rsGetSurvey = [db executeQuery:@"select * from su_survey where created_by = ?",userId];
        
        while ([rsGetSurvey next]) {
            
            //check if this survey got atleast 1 answer, if not, don't add this survery
            FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rsGetSurvey intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rsGetSurvey intForColumn:@"survey_id"]]];
            
            BOOL checkBool = NO;
            
            NSMutableArray *answers = [[NSMutableArray alloc] init];
            while ([check next]) {
                checkBool = YES;
                [answers addObject:[check resultDictionary]];
            }
            
            if(checkBool == YES)
            {
                
                NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                
                [row setObject:answers forKey:@"answers"];
                
                [row setObject:[rsGetSurvey resultDictionary] forKey:@"survey"];
                
                //get address details
                NSNumber *clientAddressId = [NSNumber numberWithInt:[rsGetSurvey intForColumn:@"client_survey_address_id"]];
                NSNumber *addressId = [NSNumber numberWithInt:[rsGetSurvey intForColumn:@"survey_address_id"]];
                
                //if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                //  continue;
                
                FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and (client_address_id <> ? or address_id <> ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                
                BOOL thereIsAnAddress = NO;
                
                while ([rsAdd next]) {
                    thereIsAnAddress = YES;
                    [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                }
                
                [surveyArrRow addObject:row];
            }
        }
    }];

    return surveyArrRow;
}

- (NSArray *)surveyDetailForSegment:(NSInteger)segment forSurveyId:(NSNumber *)surveyId forClientSurveyId:(NSNumber *)clientSurveyId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];

    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_answers sa, su_questions sq where (sa.client_survey_id = ? or sa.survey_id = ?) and ( sa.question_id = sq.question_id)  group by sa.question_id",clientSurveyId,surveyId];
            
            while ([rs next]) {
                [arr addObject:[rs resultDictionary]];
            }
        }];
    }
    
    else
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs;
            if([surveyId intValue] > 0)
                rs = [db executeQuery:@"select * from su_feedback where survey_id = ? order by client_feedback_id desc",surveyId];
            else
                rs = [db executeQuery:@"select * from su_feedback where client_survey_id = ? order by client_feedback_id desc",clientSurveyId];
            
            while ([rs next]) {
                NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                NSMutableArray *postsArray = [[NSMutableArray alloc] init];
                
                [row setObject:[rs resultDictionary] forKey:@"feedback"];
                
                //get address details
                NSNumber *client_address_id = [NSNumber numberWithInt:[rs intForColumn:@"client_address_id"]];
                NSNumber *address_id = [NSNumber numberWithInt:[rs intForColumn:@"address_id"]];
                
                FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",client_address_id,address_id];
                
                while ([rsAdd next]) {
                    [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                }
                
                
                //get post details
                NSNumber *client_feedback_id = [NSNumber numberWithInt:[rs intForColumn:@"client_feedback_id"]];
                NSNumber *feedback_id = [NSNumber numberWithInt:[rs intForColumn:@"feedback_id"]];
                
                FMResultSet *rsFeedBackIssue = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ? or feedback_id = ?",client_feedback_id,feedback_id];
                while ([rsFeedBackIssue next]) {
                    
                    NSNumber *client_post_id = [NSNumber numberWithInt:[rsFeedBackIssue intForColumn:@"client_post_id"]];
                    NSNumber *post_id = [NSNumber numberWithInt:[rsFeedBackIssue intForColumn:@"post_id"]];
                    
                    FMResultSet *rspost = [db executeQuery:@"select * from post where client_post_id = ? or post_id = ?",client_post_id,post_id];
                    
                    while ([rspost next]) {
                        [postsArray addObject:[rspost resultDictionary]];
                    }
                    
                    [row setObject:postsArray forKey:@"post"];
                }
                
                //get contract types
                FMResultSet *rsContractTypes = [db executeQuery:@"select * from contract_type"];
                NSMutableArray *contractTypesArray = [[NSMutableArray alloc] init];
                while ([rsContractTypes next]) {
                    [contractTypesArray addObject:[rsContractTypes resultDictionary]];
                }
                [row setObject:contractTypesArray forKey:@"contractTypes"];
                
                //store!
                [arr addObject:row];
            }
        }];
    }
    
    return arr;
}

- (NSDictionary *)surveyForId:(NSNumber *)surveyId forAddressType:(NSString *)addressType
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        NSDictionary *surveyDict;
        NSDictionary *addressDict;

        int surveyAddressId = 0;
        int residentAddressId = 0;
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            surveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            residentAddressId = [rs intForColumn:@"client_resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        //get address
        if([addressType isEqualToString:@"survey"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:surveyAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        //get address
        if([addressType isEqualToString:@"resident"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:residentAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        if(addressDict != nil)
            [dict setObject:addressDict forKey:@"address"];
        
    }];
    
    return dict;
}


- (NSDictionary *)surveDetailForId:(NSNumber *)surveyId forClientSurveyId:(NSNumber *)clientSurveyId
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ? or survey_id = ?",clientSurveyId,surveyId];
        NSDictionary *surveyDict;
        NSDictionary *residentAddressDict;
        NSDictionary *surveyAddressDict;
        
        int clientSurveyAddressId = 0;
        int clientResidentAddressId = 0;
        
        int surveyAddressId = 0;
        int residentAddressId = 0;
        
        
        
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            clientSurveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            clientResidentAddressId = [rs intForColumn:@"client_resident_address_id"];
            
            surveyAddressId = [rs intForColumn:@"survey_address_id"];
            residentAddressId = [rs intForColumn:@"resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and address_id != ?",[NSNumber numberWithInt:clientSurveyAddressId],[NSNumber numberWithInt:surveyAddressId],[NSNumber numberWithInt:0]];
            
            while ([rsAddress next]) {
                surveyAddressDict = [rsAddress resultDictionary];
            }
        
        
            FMResultSet *rsAddress2 = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and address_id != ?",[NSNumber numberWithInt:clientResidentAddressId],[NSNumber numberWithInt:residentAddressId],[NSNumber numberWithInt:0]];
            
            while ([rsAddress2 next]) {
                residentAddressDict = [rsAddress2 resultDictionary];
            }
        
        if(residentAddressDict != nil)
            [dict setObject:residentAddressDict forKey:@"residentAddress"];
        
        if(surveyAddressDict != nil)
            [dict setObject:surveyAddressDict forKey:@"surveyAddress"];
        
    }];
    
    return dict;
}

- (NSArray *)fetchSurveyForSegment:(int) segment
{
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    __block BOOL atleastOneOverdueWasFound = NO;
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where isMine = ? order by survey_date desc",[NSNumber numberWithBool:YES]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*23*59*59];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970] + 0.483;//retain the 0.483 coz existing data in already have 0.483 in date time
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    //don't add overdue survey!
                    if(atleastOneOverdueWasFound == NO)
                    {
                        [row setObject:[NSNumber numberWithBool:NO] forKey:@"overdue"];
                        [surveyArr addObject:row];
                    }
                    else
                        [row setObject:[NSNumber numberWithBool:YES] forKey:@"overdue"];
                    
                }
            }
        }];
    }
    else if(segment == 1)
    {
        NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetSurvey = [db executeQuery:@"select created_by from su_survey where isMine = ? group by created_by order by survey_date desc",[NSNumber numberWithBool:NO]];
            
            while ([rsGetSurvey next]) {
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                            continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",clientAddressId,addressId];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        NSArray *cleanSurveyArray = [[NSOrderedSet orderedSetWithArray:surveyArr] array];
        return cleanSurveyArray;
    }
    else
    {
        __block BOOL atleastOneOverdueWasFound = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where isMine = ? order by survey_date desc",[NSNumber numberWithBool:YES]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                if([clientSurveyId intValue] == 0 && [surveyId intValue] == 0)
                    continue;
                
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    if([feedBackId intValue] == 0 && [clientFeedBackId intValue] == 0)
                        continue;
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        if([client_post_id intValue] == 0 && [post_id intValue] == 0)
                            continue;
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*23*59*59];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970] + 0.483;//retain the 0.483 coz existing data in already have 0.483 in date time
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                        continue;
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,zero,zero];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    if(atleastOneOverdueWasFound == YES)
                    {
                        [surveyArr addObject:row];
                    }
                }
            }
        }];
    }
    
    
    return surveyArr;
}

- (void)purgeInActiveSurvey
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSNumber *numberOfInActiveDays = [NSNumber numberWithInt:3]; //default
        
        
        FMResultSet *rsGetInactiveDays = [db executeQuery:@"select inactiveDays from settings"];
        
        while ([rsGetInactiveDays next]) {
            numberOfInActiveDays = [NSNumber numberWithInt:[rsGetInactiveDays intForColumn:@"inactiveDays"]];
        }
        
        
        //get surveys to keep
        NSDate *now = [NSDate date];
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *daysAgo = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:-[numberOfInActiveDays intValue]*23*59*59];
        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
        
        
        FMResultSet *rsSurveysToKeep = [db executeQuery:@"select s.survey_id \
                                        from su_survey s \
                                        left join su_feedback f on s.survey_id = f.survey_id \
                                        left join su_feedback_issue fs on f.feedback_id = fs.feedback_id \
                                        left join post p on fs.post_id = p.post_id \
                                        where( \
                                              (fs.feedback_issue_id is null and s.survey_date > ? ) \
                                              or \
                                        (fs.feedback_issue_id is not null and fs.post_id = 0 and (fs.status <> 4 or (fs.status = 4 and fs.updated_on > ? ))) \
                                              or \
                                        (fs.feedback_issue_id is not null and fs.post_id > 0 and (p.status <> 4 or(p.status = 4 and p.updated_on > ?))) \
                                        ) \
                                        group by s.survey_id",[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithDouble:timestampDaysAgo]];
        
        NSMutableArray *surveyIdsArr = [[NSMutableArray alloc] init];

        while ([rsSurveysToKeep next]) {
            [surveyIdsArr addObject:[NSNumber numberWithInt:[rsSurveysToKeep intForColumn:@"survey_id"]]];
        }
        
        
        //start deleting data not found in stringSurveyIdArray
        NSString *stringSurveyIdArray = [surveyIdsArr componentsJoinedByString:@","];
        
        NSString *surveyQ = [NSString stringWithFormat:@"select * from su_survey where survey_id not in (%@)",stringSurveyIdArray];
        
        FMResultSet *rsSurveyToDelete = [db executeQuery:surveyQ];
        
        while ([rsSurveyToDelete next]) {

            NSNumber *surveyId = [NSNumber numberWithInt:[rsSurveyToDelete intForColumn:@"survey_id"]];
            NSNumber *survey_address_id = [NSNumber numberWithInt:[rsSurveyToDelete intForColumn:@"survey_address_id"]];
            NSNumber *resident_address_id = [NSNumber numberWithInt:[rsSurveyToDelete intForColumn:@"resident_address_id"]];


            //traverse feedback
            FMResultSet *rsFeedback = [db executeQuery:@"select feedback_id from su_feedback where survey_id = ?",surveyId];
            NSMutableArray *feebackIdArrays = [[NSMutableArray alloc] init];
            while ([rsFeedback next]) {
                [feebackIdArrays addObject:[NSNumber numberWithInt:[rsFeedback intForColumn:@"feedback_id"]]];
                
                //delete this feedback
                BOOL delFeedback = [db executeUpdate:@"delete from su_feedback where feedback_id = ?",[NSNumber numberWithInt:[rsFeedback intForColumn:@"feedback_id"]]];
                if(!delFeedback)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            //delete feedback_issue
            for (int i = 0; i < feebackIdArrays.count; i++) {
                NSNumber *theFeedBackId = [feebackIdArrays objectAtIndex:i];
                BOOL delFIssue = [db executeUpdate:@"delete from su_feedback_issue where feedback_id = ?",theFeedBackId];
                if (!delFIssue) {
                    *rollback = YES;
                    return;
                }
            }
            
            
            //delete address
            BOOL delSurAddress = [db executeUpdate:@"delete from su_address where address_id = ?",survey_address_id];
            if(!delSurAddress)
            {
                *rollback = YES;
                return;
            }
            
            BOOL delResAddress = [db executeUpdate:@"delete from su_address where address_id = ?",resident_address_id];
            if(!delResAddress)
            {
                *rollback = YES;
                return;
            }
            
            
            //delete answers
            BOOL delAnswers = [db executeUpdate:@"delete from su_answers where survey_id = ?",surveyId];
            if(!delAnswers)
            {
                *rollback = YES;
                return;
            }
            
            
            //delete survey
            BOOL delSurvey = [db executeUpdate:@"delete from su_survey where survey_id = ?",surveyId];
            if(!delSurvey)
            {
                *rollback = YES;
                return;
            }
        }
    }];
}


- (NSArray *)surveyListForSegment:(int)segment
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *daysAgo = [[NSCalendar currentCalendar] dateFromComponents:comps];
    double timestampDaysAgo = [daysAgo timeIntervalSince1970];
    
    if(segment == 0)
    {
        /*
         select s.* from su_survey s left join su_feedback f on s.survey_id = f.survey_id left join su_feedback_issue fs on f.feedback_id = fs.feedback_id left join post p on fs.post_id = p.post_id where((fs.feedback_issue_id is null and s.survey_date > 1435964548 )                              or (fs.feedback_issue_id is not null and fs.post_id = 0 and (fs.status <> 4 or (fs.status = 4 and fs.updated_on > 1435964548 )))                              or (fs.feedback_issue_id is not null and fs.post_id > 0 and (p.status <> 4 or(p.status = 4 and p.updated_on > 1435964548)))
         ) and s.created_by in (select user_id from block_user_mapping where user_id != 'rawi') group by s.survey_id order by s.survey_date desc
         */
    }
    else if (segment == 1)
    {
        /*
         select s.* from su_survey s
         left join su_feedback f on f.survey_id = s.survey_id or f.client_survey_id = s.client_survey_id
         left join su_feedback_issue fi on f.feedback_id = fi.feedback_id or f.client_feedback_id = fi.client_feedback_id
         left join post p on fi.post_id = p.post_id or fi.client_post_id = p.client_post_id
         where s.created_by in (select user_id from block_user_mapping where user_id != 'rawi') order by s.survey_date desc;
         */
    }
    else
    {
        /*
         select s.* from su_survey s
         left join su_feedback f on f.survey_id = s.survey_id or f.client_survey_id = s.client_survey_id
         left join su_feedback_issue fi on f.feedback_id = fi.feedback_id or f.client_feedback_id = fi.client_feedback_id
         left join post p on fi.post_id = p.post_id or fi.client_post_id = p.client_post_id
         where p.dueDate <= 1435924799000 and s.created_by = 'rawi' order by s.survey_date desc
         */
    }
    
    
    return arr;
    
}

@end
