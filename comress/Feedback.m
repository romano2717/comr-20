//
//  Feedback.m
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Feedback.h"

@implementation Feedback

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSDictionary *)fullFeedbackDetailsForFeedbackClientId:(NSNumber *)clientFeedbackId
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsF = [db executeQuery:@"select * from su_feedback where client_feedback_id = ?",clientFeedbackId];
        while ([rsF next]) {
            [dict setObject:[rsF resultDictionary] forKey:@"feedback"];
            
            NSNumber *clientAddressId = [NSNumber numberWithInt:[rsF intForColumn:@"client_address_id"]];

            //check if this feedback got feedback_issues and related post
            FMResultSet *rsGetFeedBackIssues = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ?",clientFeedbackId];

            NSMutableArray *feedbackIssuesAndPostArr = [[NSMutableArray alloc] init];
            NSMutableDictionary *feedbackIssuesDict = [[NSMutableDictionary alloc] init];
            
            while ([rsGetFeedBackIssues next]) {
                [feedbackIssuesDict setObject:[rsGetFeedBackIssues resultDictionary] forKey:@"feedbackIssues"];
                
                NSNumber *client_post_id = [NSNumber numberWithInt:[rsGetFeedBackIssues intForColumn:@"client_post_id"]];
                //get the post associated with this feedback_issue
                
                
                FMResultSet *rsGetPosts = [db executeQuery:@"select * from post where client_post_id = ?",client_post_id];
                while ([rsGetPosts next]) {
                    [feedbackIssuesDict setObject:[rsGetPosts resultDictionary] forKey:@"post"];
                }
                [feedbackIssuesAndPostArr addObject:feedbackIssuesDict];
            }
            [dict setObject:feedbackIssuesAndPostArr forKey:@"feedBackIssues"];
            
            //get the address details
            FMResultSet *rsGetAddsDetails = [db executeQuery:@"select * from su_address where client_address_id = ?",clientAddressId];
            while ([rsGetAddsDetails next]) {
                [dict setObject:[rsGetAddsDetails resultDictionary] forKey:@"address"];
            }
        }
    }];
    
    
    return dict;
}

@end
