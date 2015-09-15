//
//  Schedule.m
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Schedule.h"

@implementation Schedule

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchScheduleForMe
{
    NSMutableArray *skedArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsSked = [db executeQuery:@"select * from ro_schedule group by w_blkid order by w_scheduledate asc"];
        
        while ([rsSked next]) {
            FMResultSet *blockInfo = [db executeQuery:@"select * from blocks where block_id = ? group by block_id", [NSNumber numberWithInt:[rsSked intForColumn:@"w_blkid"]]];
            
            while ([blockInfo next]) {
                [skedArr addObject:[blockInfo resultDictionary]];
            }
        }
        
        //get all the blocks of this user
        FMResultSet *blocksUser = [db executeQuery:@"select * from blocks_user"];
        NSMutableArray *blocksUserArr = [[NSMutableArray alloc] init];
        while ([blocksUser next]) {
            NSNumber *blockId = [NSNumber numberWithInt:[blocksUser intForColumn:@"block_id"]];
            
            [blocksUserArr addObject:blockId];
        }
        
        //remove blocks from matchBlocksForSked that doesn't belong to blocks_user
        for (int i = 0; i < skedArr.count; i++) {
            NSDictionary *dict = [skedArr objectAtIndex:i];
            
            NSNumber *blockId = [NSNumber numberWithInt:[[dict valueForKey:@"block_id"] intValue]];
            
            if([blocksUserArr containsObject:blockId] == NO)
            {
                [skedArr removeObjectAtIndex:i];
            }
        }
    }];
    

    return skedArr;
}


- (NSArray *)fetchScheduleForOthersAtPage:(NSNumber *)limit
{
    NSNumber *start = [NSNumber numberWithInt:0];
    
    NSMutableArray *skedArr = [[NSMutableArray alloc] init];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        FMResultSet *rsblk = [db executeQuery:@"select b.block_id,b.block_no,b.street_name, rs.* from blocks b, ro_schedule rs, blocks_user bu where b.block_id = rs.w_blkid and rs.w_blkid != bu.block_id group by rs.w_blkid"];
        
        while ([rsblk next]) {
            
            NSDictionary *blockDict = [NSDictionary dictionaryWithObject:[rsblk resultDictionary] forKey:[NSString stringWithFormat:@"%d",[rsblk intForColumn:@"block_id"]]];

            [skedArr addObject:blockDict];
        }
        
        //add the rest of the blocks that are not found in blocks_users
        FMResultSet *rsAllBlk = [db executeQuery:@"select * from blocks where block_id not in(select block_id from blocks_user) limit ?, ?",start,limit];
        
        while ([rsAllBlk next]) {
            NSDictionary *blockDict = [NSDictionary dictionaryWithObject:[rsAllBlk resultDictionary] forKey:[NSString stringWithFormat:@"%d",[rsAllBlk intForColumn:@"block_id"]]];
            
            [skedArr addObject:blockDict];
        }

    }];
    
    return skedArr;
}


- (NSArray *)fetchScheduleForOthersAtPage2:(NSNumber *)limit
{
    NSNumber *start = [NSNumber numberWithInt:0];
    
    NSMutableArray *skedArr = [[NSMutableArray alloc] init];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsBlocks = [db executeQuery:@"select * from blocks where block_id not in (select block_id from blocks_user) limit ? , ?",start,limit];
        
        while ([rsBlocks next]) {
            [skedArr addObject:[rsBlocks resultDictionary]];
        }
        
    }];
    
    return skedArr;
}

- (NSArray *)fetchScheduleForOthersAtPage3:(NSNumber *)limit
{
    NSNumber *start = [NSNumber numberWithInt:0];
    
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSMutableArray *activeSked = [[NSMutableArray alloc] init];
    NSMutableArray *inactiveSked = [[NSMutableArray alloc] init];
    
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
    
    comps.hour = 0;
    comps.minute = 0;
    comps.second = 0;
    
    NSDate *newDate = [cal dateFromComponents:comps ];
    
    double timteStamp = [newDate timeIntervalSince1970];
    NSNumber *NStimeStamp = [NSNumber numberWithDouble:timteStamp];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsBlocks = [db executeQuery:@"select * from blocks where block_id in (select block_id from ro_sup_activeBlocks where activeDate = ?) ",NStimeStamp];
        
        while ([rsBlocks next]) {
            [activeSked addObject:[rsBlocks resultDictionary]];
        }
        
        
        //add the rest of the blocks from blocks where not in rsBlocks
        FMResultSet *rsBlocks2 = [db executeQuery:@"select * from blocks where block_id not in (select block_id from ro_sup_activeBlocks where activeDate = ?) and block_id not in (select block_id from blocks_user) limit ?, ?",NStimeStamp,start,limit];
        
        while ([rsBlocks2 next]) {
            [inactiveSked addObject:[rsBlocks2 resultDictionary]];
        }
        
        [arr addObject:@{@"active":activeSked,@"inactive":inactiveSked}];
        
    }];
    
    return arr;
}


- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from ro_schedule_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into ro_schedule_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update ro_schedule_last_req_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

- (NSDictionary *)scheduleForBlockId:(NSNumber *)blockId
{
    __block NSDictionary *dict;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from ro_schedule rs, blocks b where w_blkid = ? and rs.w_blkid = b.block_id group by w_blkid",blockId];
        
        while ([rs next]) {
            dict = [rs resultDictionary];
        }
    }];
    
    return dict;
}

//NOTE: checkListId is the auto increment id of the local db and NOT the w_chklistid id from server db
- (BOOL)saveOrFinishScheduleWithId:(NSNumber *)scheduleId checklistId:(NSNumber *)checkListId checkAreaId:(NSNumber *)checkAreaId withStatus:(NSNumber *)status
{
    __block BOOL ok = YES;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;

        NSDate *now = [NSDate date];
        
        if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SPO"])
        {
            FMResultSet *rsChk = [db executeQuery:@"select * from ro_checklist where id = ?",checkListId];
            while ([rsChk next]) {
                NSNumber *w_checklistid = [NSNumber numberWithInt:[[rsChk valueForKey:@"w_chklistid"] intValue]];
                
                //insert!
                ok = [db executeUpdate:@"insert into ro_inspectionresult (w_scheduleid,w_checklistid,w_chkareaid,w_reportby,w_spochecked,w_status,w_created_on,chkAIid) values(?,?,?,?,?,?,?,?)",scheduleId,w_checklistid,checkAreaId,[myDatabase.userDictionary valueForKey:@"user_id"],[NSNumber numberWithInt:1],status,now,checkListId];
                
                if(!ok)
                {
                    ok = NO;
                    *rollback = YES;
                    return;
                }
                
                else
                {
                    //update ro_schedule table
                    if([status intValue] == 2) //(updated when SPO finished the schedule)
                    {
                        BOOL up =  [db executeUpdate:@"update ro_schedule set w_spochk = ? where w_scheduleid = ?",now,scheduleId];
                        if(!up)
                        {
                            ok = NO;
                            *rollback = YES;
                            return;
                        }
                    }
                    
                    BOOL up2 = [db executeUpdate:@"update ro_schedule set w_flag = ? where w_scheduleid",status,scheduleId];
                    if(!up2)
                    {
                        ok = NO;
                        *rollback = YES;
                        return;
                    }
                }
            }
        }
        else
        {
            FMResultSet *rsChk = [db executeQuery:@"select * from ro_checklist where id = ?",checkListId];
            while ([rsChk next]) {
                NSNumber *w_checklistid = [NSNumber numberWithInt:[rsChk intForColumn:@"w_chklistid"]];
                
                //insert!
                ok = [db executeUpdate:@"insert into ro_inspectionresult (w_scheduleid,w_checklistid,w_chkareaid,w_reportby,w_checked,w_status,w_created_on,chkAIid) values(?,?,?,?,?,?,?,?)",scheduleId,w_checklistid,checkAreaId,[myDatabase.userDictionary valueForKey:@"user_id"],[NSNumber numberWithInt:1],status,now,checkListId];
                
                if(!ok)
                {
                    ok = NO;
                    *rollback = YES;
                    return;
                }
                else
                {
                    //update ro_schedule table
                    if([status intValue] == 2)
                    {
                        BOOL up = [db executeUpdate:@"update ro_schedule set w_actendtime = ?, w_supchk = ?, w_actualdate = ? where w_scheduleid = ?",now,now,now,scheduleId];
                        if(!up)
                        {
                            ok = NO;
                            *rollback = YES;
                            return;
                        }
                    }
                    
                    BOOL up2 = [db executeUpdate:@"update ro_schedule set w_supflag = ? where w_scheduleid = ?",status,scheduleId];
                    if(!up2)
                    {
                        ok = NO;
                        *rollback = YES;
                        return;
                    }
                }
            }
        }
    }];
    
    return ok;
}

//NOTE: checkListId is the w_chklistid id from server db
- (BOOL)saveOrFinishScheduleWithId2:(NSNumber *)scheduleId checklistId:(NSNumber *)checkListId checkAreaId:(NSNumber *)checkAreaId withStatus:(NSNumber *)status
{
    __block BOOL ok = YES;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        
        NSDate *now = [NSDate date];
        
        if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SPO"])
        {
            FMResultSet *rsChk = [db executeQuery:@"select * from ro_checklist where w_chklistid = ?",checkListId];
            while ([rsChk next]) {
                NSNumber *w_checklistid = [NSNumber numberWithInt:[[rsChk valueForKey:@"w_chklistid"] intValue]];
                
                //insert!
                ok = [db executeUpdate:@"insert into ro_inspectionresult (w_scheduleid,w_checklistid,w_chkareaid,w_reportby,w_spochecked,w_status,w_created_on,chkAIid) values(?,?,?,?,?,?,?,?)",scheduleId,w_checklistid,checkAreaId,[myDatabase.userDictionary valueForKey:@"user_id"],[NSNumber numberWithInt:1],status,now,checkListId];
                
                if(!ok)
                {
                    ok = NO;
                    *rollback = YES;
                    return;
                }
                
                else
                {
                    //update ro_schedule table
                    if([status intValue] == 2) //(updated when SPO finished the schedule)
                    {
                        BOOL up =  [db executeUpdate:@"update ro_schedule set w_spochk = ? where w_scheduleid = ?",now,scheduleId];
                        if(!up)
                        {
                            ok = NO;
                            *rollback = YES;
                            return;
                        }
                    }
                    
                    BOOL up2 = [db executeUpdate:@"update ro_schedule set w_flag = ? where w_scheduleid",status,scheduleId];
                    if(!up2)
                    {
                        ok = NO;
                        *rollback = YES;
                        return;
                    }
                }
            }
        }
        else
        {
            FMResultSet *rsChk = [db executeQuery:@"select * from ro_checklist where w_chklistid = ?",checkListId];
            while ([rsChk next]) {
                NSNumber *w_checklistid = [NSNumber numberWithInt:[rsChk intForColumn:@"w_chklistid"]];
                
                //insert!
                ok = [db executeUpdate:@"insert into ro_inspectionresult (w_scheduleid,w_checklistid,w_chkareaid,w_reportby,w_checked,w_status,w_created_on,chkAIid) values(?,?,?,?,?,?,?,?)",scheduleId,w_checklistid,checkAreaId,[myDatabase.userDictionary valueForKey:@"user_id"],[NSNumber numberWithInt:1],status,now,checkListId];
                
                if(!ok)
                {
                    ok = NO;
                    *rollback = YES;
                    return;
                }
                else
                {
                    //update ro_schedule table
                    if([status intValue] == 2)
                    {
                        BOOL up = [db executeUpdate:@"update ro_schedule set w_actendtime = ?, w_supchk = ?, w_actualdate = ? where w_scheduleid = ?",now,now,now,scheduleId];
                        if(!up)
                        {
                            ok = NO;
                            *rollback = YES;
                            return;
                        }
                    }
                    
                    BOOL up2 = [db executeUpdate:@"update ro_schedule set w_supflag = ? where w_scheduleid = ?",status,scheduleId];
                    if(!up2)
                    {
                        ok = NO;
                        *rollback = YES;
                        return;
                    }
                }
            }
        }
    }];
    
    return ok;
}

- (NSArray *)checkListForScheduleId:(NSNumber *)scheduleId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select rs.w_jobtypeid, rs.w_scheduleid, rc.* from ro_schedule rs, ro_checklist rc where rs.w_scheduleid = ? and rs.w_jobtypeId = rc.w_jobtypeid",scheduleId];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}
@end
