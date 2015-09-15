//
//  Comment_noti.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Comment_noti : NSObject
{
    Database *myDatabase;
}
@property (nonatomic) int post_id;
@property (nonatomic) int comment_id;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *user_id;

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

@end
