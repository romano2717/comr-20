//
//  PostImage.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "Users.h"

@interface PostImage : NSObject
{
    Database *myDatabase;
    Users *users;  
}

@property (nonatomic, strong) NSNumber *client_post_image_id;
@property (nonatomic, strong) NSNumber *post_image_id;
@property (nonatomic, strong) NSNumber *client_post_id;
@property (nonatomic, strong) NSNumber *post_id;
@property (nonatomic, strong) NSNumber *client_comment_id;
@property (nonatomic, strong) NSNumber *comment_id;
@property (nonatomic, strong) NSString *image_path;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *downloaded;
@property (nonatomic, strong) NSString *uploaded;
@property (nonatomic, strong) NSNumber *image_type;

-(long long)savePostImageWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)imagesTosend;
- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;
@end
