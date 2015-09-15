//
//  Users.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Users.h"

@implementation Users

@synthesize client_id,
full_name,
guid,
email,
device_token,
company_id,
user_id,
company_name,
group_id,
group_name,
device_id;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *userRs;
            NSString *user_guid;
            
            FMResultSet *rs = [db executeQuery:@"select user_guid from client"];
            if([rs next])
            {
                user_guid = [rs stringForColumn:@"user_guid"];
            }
            
            if(user_guid != nil)
            {
                userRs = [db executeQuery:@"select * from users where guid = ?",user_guid];
                
                while ([userRs next]) {
                    client_id = [NSNumber numberWithInt:[userRs intForColumn:@"client_id"]];
                    full_name = [userRs stringForColumn:@"full_name"];
                    guid = [userRs stringForColumn:@"guid"];
                    
                    client_id = [NSNumber numberWithInt:[userRs intForColumn:@"client_id"]];
                    full_name = [userRs stringForColumn:@"full_name"];
                    guid = [userRs stringForColumn:@"guid"];
                    email = [userRs stringForColumn:@"email"];
                    device_token = [userRs stringForColumn:@"device_token"];
                    company_id = [userRs stringForColumn:@"company_id"];
                    user_id = [userRs stringForColumn:@"user_id"];
                    company_name = [userRs stringForColumn:@"company_name"];
                    group_id = [NSNumber numberWithInt:[[userRs stringForColumn:@"group_id"] intValue]];
                    group_name = [userRs stringForColumn:@"group_name"];
                    device_id = [NSNumber numberWithInt:[userRs intForColumn:@"device_id"]];
                }
            }
        }];
    }
    return self;
}

@end
