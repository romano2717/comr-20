//
//  Device_token.m
//  comress
//
//  Created by Diffy Romano on 13/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Device_token.h"

@implementation Device_token

@synthesize device_token;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select device_token from device_token"];
            
            while ([rs next]) {
                device_token = [rs stringForColumn:@"device_token"];
            }
        }];
    }
    return self;
}

@end
