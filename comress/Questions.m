//
//  Questions.m
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Questions.h"

@implementation Questions

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from su_questions_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into su_questions_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update su_questions_last_req_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

- (NSArray *)questions
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        FMResultSet *rs = [db executeQuery:@"select * from su_questions"];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}

@end
