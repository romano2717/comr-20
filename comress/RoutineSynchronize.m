//
//  RoutineSynchronize.m
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineSynchronize.h"

@implementation RoutineSynchronize

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    return self;
}

+(id)sharedRoutineSyncManager {
    static RoutineSynchronize *sharedMySyncManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMySyncManager = [[self alloc] init];
    });
    return sharedMySyncManager;
}

- (void)startSync
{
    if(myDatabase.initializingComplete == NO)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startSync];
        });
        
        return;
    }
    else
        [self uploadUnlockBlockInfoFromSelf:YES];
}

- (void)stopSync
{

}

- (void)uploadUnlockBlockInfoFromSelf:(BOOL)fromSelf
{
    DDLogVerbose(@"uploadUnlockBlockInfoFromSelf");
    
    NSMutableArray *unlockList = [[NSMutableArray alloc] init];
    
    NSNumber *needToSync = [NSNumber numberWithInt:1];
    NSNumber *syncIsFinished = [NSNumber numberWithInt:2];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"select * from rt_blk_schedule where sync_flag = ?",needToSync];
        
        while ([rs next]) {
            NSNumber *BlockId = [NSNumber numberWithInt:[rs intForColumn:@"blk_id"]];
            NSString *UserId = [rs stringForColumn:@"user_id"];
            NSString *ScheduleDate = [myDatabase createWcfDateWithNsDate:[rs dateForColumn:@"schedule_date"]];
            NSString *Barcode = [rs stringForColumn:@"barcode"];
            NSNumber *Latitude = [NSNumber numberWithFloat:[rs doubleForColumn:@"latitude"]];
            NSNumber *Longitude = [NSNumber numberWithFloat:[rs doubleForColumn:@"longitude"]];
            
            [unlockList addObject:@{@"BlockId":BlockId,@"UserId":UserId,@"ScheduleDate":ScheduleDate,@"Barcode":Barcode,@"Latitude":Latitude,@"Longitude":Longitude}];
        }
    }];
    
    if(unlockList.count == 0)
    {
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadScheduleImageFromSelf:fromSelf];
            });
        }
        
        return;
    }
    
    NSDictionary *params = @{@"unlockList":unlockList};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_upload_unlock_block_info] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *AckUnlockObj = [responseObject objectForKey:@"AckUnlockObj"];
        
        for (NSDictionary *dict in AckUnlockObj) {
            NSNumber *BlockId = [NSNumber numberWithInt:[[dict valueForKey:@"BlockId"] intValue]];
            NSString *ErrorMessage = [dict valueForKey:@"ErrorMessage"];
            NSString *ScheduleDate = [dict valueForKey:@"ScheduleDate"];
            NSDate *ScheduleDateNsDate = [myDatabase createNSDateWithWcfDateString:ScheduleDate];
            NSNumber *ScheduleDateNsDateEpoch = [NSNumber numberWithDouble:[ScheduleDateNsDate timeIntervalSince1970]];
            NSString *UserId = [dict valueForKey:@"UserId"];
            
            if([ErrorMessage isEqual:[NSNull null]])
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL up = [db executeUpdate:@"update rt_blk_schedule set sync_flag = ? where blk_id = ? and schedule_date = ? and user_id = ?",syncIsFinished, BlockId, ScheduleDateNsDateEpoch, UserId];
                    
                    if(!up)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
        }
        
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadScheduleImageFromSelf:fromSelf];
            });
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadScheduleImageFromSelf:fromSelf];
            });
        }
        
    }];
}

- (void)uploadScheduleImageFromSelf:(BOOL)fromSelf
{
    DDLogVerbose(@"uploadScheduleImageFromSelf");
    
    __block NSArray *scheduleImageList;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSNumber *zero = [NSNumber numberWithInt:0];
        
        FMResultSet *rs = [db executeQuery:@"select * from rt_schedule_image where schedule_image_id = ? limit 0,1",zero];
        
        while ([rs next]) {
            NSNumber *CilentScheduleImageId = [NSNumber numberWithInt:[rs intForColumn:@"client_schedule_image_id"]];
            NSNumber *ScheduleId = [NSNumber numberWithInt:[rs intForColumn:@"schedule_id"]];
            NSNumber *CheckListId = [NSNumber numberWithInt:[rs intForColumn:@"checklist_id"]];
            NSNumber *ImageType = [NSNumber numberWithInt:[rs intForColumn:@"image_type"]];
            NSString *Remark = [rs stringForColumn:@"remark"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[rs stringForColumn:@"image_name"]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
                continue ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            NSString *imageString = [imageData base64EncodedStringWithSeparateLines:NO];
            
            NSDictionary *dict = @{@"CilentScheduleImageId":CilentScheduleImageId,@"ScheduleId":ScheduleId,@"CheckListId":CheckListId,@"ImageType":ImageType,@"Remark":Remark,@"Image":imageString};
            
            scheduleImageList = [NSArray arrayWithObject:dict];
        }
    }];
    
    if(scheduleImageList.count == 0)
    {
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self nextSyncMethod];
            });
        }
        
        return;
    }
    
    NSDictionary *params = @{@"scheduleImageList":scheduleImageList};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_upload_schedule_image] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *AckScheduleImageObj = [responseObject objectForKey:@"AckScheduleImageObj"];
        
        for (NSDictionary *dict in AckScheduleImageObj) {
            NSNumber *CilentScheduleImageId = [NSNumber numberWithInt:[[dict valueForKey:@"CilentScheduleImageId"] intValue]];
            NSString *ErrorMessage = [dict valueForKey:@"ErrorMessage"];
            NSNumber *ScheduleImageId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleImageId"] intValue]];
            
            if([ErrorMessage isEqual:[NSNull null]])
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    BOOL ups = [db executeUpdate:@"update rt_schedule_image set schedule_image_id = ? where client_schedule_image_id = ?",ScheduleImageId,CilentScheduleImageId];
                    
                    if(!ups)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                }];
            }
            
        }
        
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self nextSyncMethod];
            });
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(fromSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self nextSyncMethod];
            });
        }
        
    }];
}

- (void)nextSyncMethod
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self uploadUnlockBlockInfoFromSelf:YES];
    });
}


@end