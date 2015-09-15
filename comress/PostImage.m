//
//  PostImage.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostImage.h"
#import "NSData+Base64.h"

@implementation PostImage

@synthesize
client_post_image_id,
post_image_id,
client_post_id,
post_id,
client_comment_id,
comment_id,
image_path,
status,
downloaded,
uploaded,
image_type
;

-(id)init {
    if (self = [super init]) {

    }
    return self;
}

- (long long)savePostImageWithDictionary:(NSDictionary *)dict
{
    client_post_image_id    = [NSNumber numberWithInt:[[dict valueForKey:@"client_post_image_id"] intValue]] ;
    post_image_id           = [NSNumber numberWithInt:[[dict valueForKey:@"post_image_id"] intValue]];
    client_post_id          = [NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]];
    post_id                 = [NSNumber numberWithInt:[[dict valueForKey:@"post_id"] intValue]];
    client_comment_id       = [NSNumber numberWithInt:[[dict valueForKey:@"client_comment_id"] intValue]];
    comment_id              = [NSNumber numberWithInt:[[dict valueForKey:@"comment_id"] intValue]];
    image_path              = [dict valueForKey:@"image_path"];
    status                  = [dict valueForKey:@"status"];
    downloaded              = [dict valueForKey:@"downloaded"];
    uploaded                = [dict valueForKey:@"uploaded"];
    image_type              = [NSNumber numberWithInt:[[dict valueForKey:@"image_type"] intValue]];
    
    __block long long postClientImageId = 0;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL postImageSaved;
        
        postImageSaved = [db executeUpdate:@"insert into post_image (client_post_id,image_path,status,downloaded,uploaded,image_type) values (?,?,?,?,?,?)",client_post_id,image_path,status,downloaded,uploaded,image_type];
        
        if(!postImageSaved)
        {
            *rollback = YES;
            return;
        }
        
        else
        {
            postClientImageId = [db lastInsertRowId];
        }
    }];
    
    return postClientImageId;
}

- (NSDictionary *)imagesTosend
{

    NSNumber *zero = [NSNumber numberWithInt:0];
    NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
    __block NSMutableDictionary *imagesDict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"select * from post_image where post_image_id is null or post_image_id = ?",zero];
        users = [[Users alloc] init];
        
        while ([rs next]) {
            NSNumber *ImageType = [NSNumber numberWithInt:[rs intForColumn:@"image_type"]];
            NSNumber *CilentPostImageId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_image_id"]];
            NSNumber *PostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSNumber *CommentId = [NSNumber numberWithInt:[rs intForColumn:@"comment_id"]];
            NSString *CreatedBy = users.user_id;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[rs stringForColumn:@"image_path"]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
                continue ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            NSString *imageString = [imageData base64EncodedStringWithSeparateLines:NO];
            
            if([ImageType intValue] == 1)//post image
            {
                CommentId = [NSNumber numberWithInt:0];
            }
            else if([ImageType intValue] == 2)
            {
                PostId = [NSNumber numberWithInt:0];
            }
            
            
            NSDictionary *dict = @{@"CilentPostImageId":CilentPostImageId,@"PostId":PostId,@"CommentId":CommentId,@"CreatedBy":CreatedBy,@"ImageType":ImageType,@"Image":imageString};
            
            [imagesArray addObject:dict];
        }
        [imagesDict setObject:imagesArray forKey:@"postImageList"];
    }];
    
    
    
    return imagesDict;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from post_image_last_request_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into post_image_last_request_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update post_image_last_request_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}


@end
