//
//  Comment.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "ImageOptions.h"


@interface Comment : NSObject
{
    Database *myDatabase;
    ImageOptions *imgOpts;

}

@property (nonatomic) int client_comment_id;
@property (nonatomic) int comment_id;
@property (nonatomic) int client_post_id;
@property (nonatomic) int post_id;
@property (nonatomic, weak) NSString *comment;
@property (nonatomic, weak) NSDate *comment_on;
@property (nonatomic, weak) NSString *comment_by;
@property (nonatomic, weak) NSString *comment_type;

- (BOOL)saveCommentWithDict:(NSDictionary *)dict;
- (NSDictionary *)commentsToSend;
- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;
@end
