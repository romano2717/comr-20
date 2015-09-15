//
//  Check_area.m
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Check_area.h"

@implementation Check_area

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)scheduleForBlock:(NSNumber *)blockId
{
    NSMutableArray *skedAdrr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsSked;
        
        if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"])
        {
            rsSked = [db executeQuery:@"select * from ro_schedule where w_blkid = ? and w_flag < ? order by w_scheduledate asc",blockId,[NSNumber numberWithInt:2]]; //saved or new
        }
        else
        {
            rsSked = [db executeQuery:@"select * from ro_schedule where w_blkid = ? and w_supflag < ? order by w_scheduledate asc",blockId,[NSNumber numberWithInt:2]]; //saved or new
        }
        
        
        while ([rsSked next]) {
            [skedAdrr addObject:[rsSked resultDictionary]];
        }
        
    }];
    
    return skedAdrr;
}

- (NSArray *)checkAreaForJobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *checkAreaArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsChkL = [db executeQuery:@"select * from ro_checklist where w_jobtypeid = ? group by w_chkareaid",jobTypeId];
        
        while ([rsChkL next]) {
            NSNumber *w_chkareaid = [NSNumber numberWithInt:[rsChkL intForColumn:@"w_chkareaid"]];
            
            FMResultSet *rsCheckArea = [db executeQuery:@"select * from ro_checkarea where w_chkareaid = ?",w_chkareaid];
            
            while ([rsCheckArea next]) {
                [checkAreaArr addObject:[rsCheckArea resultDictionary]];
            }
        }
    }];
    
    return checkAreaArr;
}

- (NSArray *)checkListForJobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *checkList = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsChkL = [db executeQuery:@"select * from ro_checklist where w_jobtypeid = ? group by w_chkareaid",jobTypeId];
        
        while ([rsChkL next]) {
            [checkList addObject:[rsChkL resultDictionary]];
        }
    }];
    
    return checkList;
}

- (NSDictionary *)checkAreaForId:(NSNumber *)checkAreaId
{
    __block NSDictionary *dict;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_checkarea where w_chkareaid = ?",checkAreaId];
        
        while ([rs next]) {
            dict = [rs resultDictionary];
        }
    }];
    
    return dict;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from ro_checkarea_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into ro_checkarea_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update ro_checkarea_last_req_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}
@end
