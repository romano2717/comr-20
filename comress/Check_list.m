//
//  Check_list.m
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Check_list.h"

@implementation Check_list


- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchCheckListForBlockId:(NSNumber *)blkId
{
    NSMutableArray *skedAdrr = [[NSMutableArray alloc] init];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsSked;
        
        if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"])
        {
            rsSked = [db executeQuery:@"select * from ro_schedule where w_blkid = ? and w_flag < ? order by w_scheduledate asc",blkId,[NSNumber numberWithInt:2]]; //saved or new
        }
        else
        {
            rsSked = [db executeQuery:@"select * from ro_schedule where w_blkid = ? and w_supflag < ? order by w_scheduledate asc",blkId,[NSNumber numberWithInt:2]]; //saved or new
        }
        

        while ([rsSked next]) {
            [skedAdrr addObject:[rsSked resultDictionary]];
        }
    }];
    
    return skedAdrr;
}

- (NSArray *)checklistForJobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *checkListArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsChkL = [db executeQuery:@"select * from ro_checklist where w_jobtypeid = ?",jobTypeId];
        
        while ([rsChkL next]) {
            [checkListArr addObject:[rsChkL resultDictionary]];
        }
    }];
    
    return checkListArr;
}


- (NSArray *)checkAreaForJobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *checkListArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsChkL = [db executeQuery:@"select * from ro_checklist where w_jobtypeid = ? group by w_chkareaid",jobTypeId];
        
        while ([rsChkL next]) {
            NSNumber *w_chkareaid = [NSNumber numberWithInt:[rsChkL intForColumn:@"w_chkareaid"]];
            
            FMResultSet *rsChkArea = [db executeQuery:@"select * from ro_checkarea where w_chkareaid = ?",w_chkareaid];
            while ([rsChkArea next]) {
                [checkListArr addObject:[rsChkArea resultDictionary]];
            }
        }
    }];
    
    return checkListArr;
}

- (NSArray *)checkListForCheckAreaId:(NSNumber *)checkAreaId JobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_checklist where w_chkareaid = ? and w_jobtypeid = ?",checkAreaId,jobTypeId];
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}

- (NSArray *)checkListForCheckAreaId:(NSNumber *)checkAreaId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_checklist where w_chkareaid = ?",checkAreaId];
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}

- (NSArray *)updatedChecklist
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_inspectionresult"];
        
        while ([rs next]) {
            DDLogVerbose(@"w_scheduleid %d",[rs intForColumn:@"w_scheduleid"]);
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from ro_checklist_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into ro_checklist_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update ro_checklist_last_req_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

- (NSArray *)inspectionResultCheckListForStatus:(NSNumber *)status
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_inspectionresult where w_status = ?",status];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    return arr;
}

@end
