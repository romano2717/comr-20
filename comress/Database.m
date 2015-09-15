//
//  Database.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Database.h"

static const int newDatabaseVersion = 21; //this database version is incremented everytime the database version is updated

@implementation Database

@synthesize initializingComplete,userBlocksInitComplete,userBlocksMappingInitComplete;


+(instancetype)sharedMyDbManager {
    static id sharedMyDbManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyDbManager = [[self alloc] init];
    });
    return sharedMyDbManager;
}

-(id)init {
    if (self = [super init]) {
        initializingComplete = 0;
        userBlocksInitComplete = 0;
        userBlocksMappingInitComplete = NO;
        
        [self copyDbToDocumentsDir];
        
        _databaseQ = [[FMDatabaseQueue alloc] initWithPath:self.dbPath];
        
        [self createClient];
        
        [self createUser];
        
        [self createAfManager];
        
        [self createDeviceToken];
        
    }
    return self;
}

- (void)createClient
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from client"];
        while ([rs next]) {
            _clientDictionary = [rs resultDictionary];
        }
    }];
    
}

- (void)createUser
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from users where is_active = ?",[NSNumber numberWithInt:1]];
        while ([rs next]) {
            _userDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createDeviceToken
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs  = [db executeQuery:@"select * from device_token"];
        while ([rs next]) {
            _deviceTokenDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createAfManager
{
//    _api_url = @"http://comresstest.selfip.com/ComressMWCF/";
//    _domain = @"http://comresstest.selfip.com/";
    
    _api_url = [NSString stringWithFormat:@"%@%@",[_clientDictionary valueForKey:@"api_url"],app_path];
    _domain = [_clientDictionary valueForKey:@"api_url"];
    
    DDLogVerbose(@"session id: %@",[_clientDictionary valueForKey:@"user_guid"]);
    
    _AfManager = [AFHTTPRequestOperationManager manager];
    _AfManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _AfManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if([_clientDictionary valueForKey:@"user_guid"] != [NSNull null])
        [_AfManager.requestSerializer setValue:[_clientDictionary valueForKey:@"user_guid"] forHTTPHeaderField:@"ComSessionId"];
    
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    policy.allowInvalidCertificates = YES;
    _AfManager.securityPolicy = policy;
}

- (NSString*)dbPath;
{
    NSArray *Paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *DocumentDir = [Paths objectAtIndex:0];
    
    return [DocumentDir stringByAppendingPathComponent:@"comress.sqlite"];
}

- (void)copyDbToDocumentsDir
{
    BOOL isExist;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    isExist = [fileManager fileExistsAtPath:[self dbPath]];
    NSString *FileDB = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"comress.sqlite"];
    if (isExist)
    {
        return;
    }
    else
    {
        NSError *error;
        
        [fileManager copyItemAtPath:FileDB toPath:[self dbPath] error:&error];
        
        if(error)
        {
            DDLogVerbose(@"settings copy error %@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            return;
        }
    }
}

- (BOOL)setInitTo:(int)flag
{
    __block BOOL ok = NO;
    
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL upClient = [db executeUpdate:@"update client set initialise = ?",[NSNumber numberWithInt:flag]];
        if(!upClient)
        {
            *rollback = YES;
            return;
        }
        else
            ok = YES;
    }];
    
    return ok;
}

#pragma - mark database migration

-(void)migrateDatabase
{
    __block NSNumber *dbVersionFlag = [NSNumber numberWithInt:0];
    
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsDbVersion = [db executeQuery:@"select version from db_version"];
        
        while ([rsDbVersion next]) {
            dbVersionFlag = [NSNumber numberWithInt:[rsDbVersion intForColumn:@"version"]];
        }
        
    }];
    
    if([dbVersionFlag intValue] == newDatabaseVersion)
        return;//latest db version, don't do any migration
    else
    {
        //create the tables
        NSArray *tablesToCreate = @[
                                    //30-apr-2015: allow crm to add image
                                    @"CREATE TABLE IF NOT EXISTS suv_crm_image (client_crm_image_id INTEGER PRIMARY KEY AUTOINCREMENT, crm_image_id INTEGER DEFAULT (0), client_crm_id INTEGER DEFAULT (0), crm_id INTEGER DEFAULT (0), image_path VARCHAR (300), uploaded BOOLEAN DEFAULT (0));",
                                    //30-apr-2015: allow crm to save post information
                                    @"CREATE TABLE IF NOT EXISTS suv_crm (client_crm_id INTEGER PRIMARY KEY AUTOINCREMENT, crm_id INTEGER DEFAULT (0), client_feed_back_issue_id INTEGER DEFAULT (0), feedback_issue_id INTEGER DEFAULT (0), description VARCHAR (300), postal_code VARCHAR (10), address VARCHAR (100), level VARCHAR (30), no_of_image INTEGER DEFAULT (0));",
                                    
                                    //11-may-2015 when PO close an issue, remarks and/or actions done is required
                                    @"CREATE TABLE IF NOT EXISTS post_close_issue_remarks (id INTEGER PRIMARY KEY AUTOINCREMENT, actions_taken VARCHAR (100), remarks VARCHAR (300), post_id INTEGER DEFAULT (0), uploaded INTEGER DEFAULT (0), client_post_id INTEGER DEFAULT (0));",
                                    
                                    //20-may-2015 block mapping for revised issue grouping
                                    @"CREATE TABLE IF NOT EXISTS block_user_mapping (id INTEGER PRIMARY KEY AUTOINCREMENT, block_id INTEGER DEFAULT (0), supervisor_id VARCHAR (50), user_id VARCHAR (50));",
                                    
                                    //21-may-2015 add division for block mapping
                                    @"ALTER TABLE block_user_mapping add division VARCHAR (30)",
                                    
                                    //21-may-2015 add dueDate for post
                                    @"ALTER TABLE post add dueDate DATE",
                                    
                                    //24-june-2015 add environment in client table
                                    @"ALTER TABLE client add environment VARCHAR (30) DEFAULT ('DEV')",
                                    
                                    //25-june-2015 add updated_on in su_feedback_issue table
                                    @"ALTER TABLE su_feedback_issue add updated_on DATE",
                                    
                                    //25-june-2015 add new table for settings
                                    @"CREATE TABLE IF NOT EXISTS settings (inactiveDays INT DEFAULT (3));",
                                    
                                    //28-jul-2015 add new tables for action settings
                                    @"CREATE TABLE if not exists set_actions_list (name VARCHAR (30), value INTEGER DEFAULT (0));",
                                    
                                    @"CREATE TABLE if not exists set_action_sequence (CurrentAction INTEGER, CurrentActionName VARCHAR (30), NextAction INTEGER, NextActionName VARCHAR (30));",
                                    
                                    @"CREATE TABLE if not exists set_action_group (ActionName VARCHAR (30), ActionValue INTEGER, GroupId INTEGER, GroupName VARCHAR (30));",
                                    
                                    //5-aug-2015 reassign process
                                    @"CREATE TABLE if not exists post_reassign (client_reassign_post_id INTEGER PRIMARY KEY AUTOINCREMENT, reassign_post_id INTEGER DEFAULT (0), client_post_id DEFAULT (0), post_id DEFAULT (0), post_group DEFAULT (0), is_uploaded DEFAULT (0));",
                                    
                                    //5-aug-2015 add isAllowedOutside flag for contract type
                                    @"ALTER TABLE contract_type add isAllowedOutside BOOLEAN DEFAULT (0)",
                                    
                                    //19-aug-2015
                                    @"ALTER TABLE post add relatedPostId INT DEFAULT(0)",
                                    
                                    
                                    //1-sept-2015
                                    @"CREATE TABLE if not exists contract_type_public (id INTEGER, contract VARCHAR (30), isAllowedOutside BOOLEAN DEFAULT (0))",
                                    
                                    
                                    //3-sept-2015 create table for routine block schedule
                                    @"CREATE TABLE if not exists rt_blk_schedule  (blk_id INTEGER, no_of_job INTEGER, schedule_date DATE, unlock BOOLEAN DEFAULT (0), noti_message TEXT, sync_flag INT, user_id VARCHAR (30), barcode VARCHAR (50), latitude DOUBLE, longitude DOUBLE)",
                                    
                                    //3-sept-2015 
                                    @"CREATE TABLE if not exists rt_blk_schedule_sync (schedule_date DATE, download_time DATE, user_id VARCHAR (30))",
                                    
                                    
                                    //7-sept-2015
                                    @"CREATE TABLE if not exists rt_schedule_detail (schedule_id INTEGER, area VARCHAR (30), job_type VARCHAR (50), schedule_date DATE, remarks VARCHAR (500), status INT DEFAULT (1), updated_by VARCHAR (30), updated_date DATE, sync_flag DEFAULT (1), checklist_sync_flag INT DEFAULT (1))",
                                    
                                    //7-sept-2015
                                    @"CREATE TABLE if not exists rt_checklist (checklist_id INTEGER, checklist_name VARCHAR (50), checkarea VARCHAR (30), is_checked BOOLEAN DEFAULT (0), schedule_id INTEGER)",
                                    
                                    //7-sept-2015
                                    @"CREATE TABLE if not exists rt_schedule_image (client_schedule_image_id INTEGER PRIMARY KEY AUTOINCREMENT, schedule_image_id INTEGER DEFAULT (0), schedule_id INTEGER, checklist_id INTEGER, image_name VARCHAR (50), image_type INT DEFAULT (0), remark VARCHAR (500))",
                                    
                                    //9-sept-2015 add jobtype id
                                    @"ALTER TABLE rt_schedule_detail add job_type_id INTEGER DEFAULT(0)",
                                    
                                    //9-sept-2015
                                    @"ALTER TABLE rt_schedule_detail add message VARCHAR (100)",
                                    
                                    
                                    //10-sept-2015
                                    @"ALTER TABLE rt_schedule_detail add MinNumberOfImage INTEGER DEFAULT (0)",
                                    @"ALTER TABLE rt_schedule_detail add MinNumberOfPair INTEGER DEFAULT (0)",
                                    @"ALTER TABLE rt_schedule_detail add imageStatus INTEGER DEFAULT (0)",
                                    
                                    
                                    //10-sept-2015
                                    @"CREATE TABLE if not exists rt_imageTemplate (CheckListId INTEGER DEFAULT (0), MinNoOfImage INTEGER DEFAULT (0), ScheduleId INTEGER DEFAULT (0), Title DEFAULT (0));"
                                    ];
        
        
        [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            db.traceExecution = NO;
            
            for (int i = 0; i < tablesToCreate.count; i++) {
                db.traceExecution = YES;
                BOOL create = [db executeUpdate:[tablesToCreate objectAtIndex:i]];

                if(!create)
                {
                    DDLogVerbose(@"warning: %@",[db lastError]);
                }
            }
        }];
        
        
        
        //update db version
        [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rsCheckDbVersion = [db executeQuery:@"select version from db_version"];
            if([rsCheckDbVersion next] == NO)
            {
                BOOL insDbVersion = [db executeUpdate:@"insert into db_version(version) values (?)",[NSNumber numberWithInt:newDatabaseVersion]];
                if(!insDbVersion)
                {
                    *rollback = YES;
                    return;
                }
            }
            else
            {
                BOOL insDbVersion = [db executeUpdate:@"update db_version set version = ?",[NSNumber numberWithInt:newDatabaseVersion]];
                if(!insDbVersion)
                {
                    *rollback = YES;
                    return;
                }
            }
        }];
    }
}


- (void)alertMessageWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString
{
    //the wcf is gmt+8 by default :-(
    //NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (void)notifyLocallyWithMessage:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (NSString *)toJsonString:(id)obj
{
    NSError *error;
    NSString *jsonString;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        DDLogVerbose(@"Got an error: %@", error);
    } else {
       jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

- (void)saveImageToComressAlbum:(UIImage *)image
{
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [self.assetsLibrary saveImage:image toAlbum:@"COMRESS" completion:^(NSURL *assetURL, NSError *error) {
        DDLogVerbose(@"Image saved");
    } failure:^(NSError *error) {
        DDLogVerbose(@"ERROR saving image to comress album: %@",error);
    }];
}

- (void)setUiAppearanceTextSize:(CGFloat)size
{
    if(size > 0)
    {
        UIFont *theFont;
        
        NSString *category = [[UIApplication sharedApplication] preferredContentSizeCategory];

        if(size == mediumText)
        {
            theFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        }
        
        else if(size == largeText)
        {
            theFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        
        else if(size == smallText)
        {
            theFont = [UIFont systemFontOfSize:smallText];
        }


        DDLogVerbose(@"set app text size to:%f",size);
        [[UILabel appearance] setFont:theFont];
        [[[UIButton appearance] titleLabel] setFont:theFont];
        [[[UITableViewCell appearance] textLabel] setFont:theFont];
    }
}



- (NSString *)createWcfDateWithNsDate: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}


@end
