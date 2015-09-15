//
//  InitializerViewController.h
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Blocks.h"
#import "Post.h"
#import "Comment.h"
#import "PostImage.h"
#import "Comment_noti.h"
#import "ImageOptions.h"
#import "UIImageView+WebCache.h"
#import "Client.h"
#import "Questions.h"

@class Post;

@interface InitializerViewController : UIViewController
{
    Database *myDatabase;
    ImageOptions *imgOpts;
    
    Blocks *blocks;
    Post *posts;
    Comment *comments;
    PostImage *postImage;
    Comment_noti *comment_noti;
    Client *client;
    Questions *questions;
    
}
@property (nonatomic, weak) IBOutlet UILabel *processLabel;
@property (nonatomic, strong) NSMutableArray *imagesArr;
@property (nonatomic) BOOL imageDownloadComplete;

- (void)checkBlockCount;

- (void)checkUserBlockCount;

- (void)checkPostCount;

- (void)checkCommentCount;

-(void)checkPostImagesCount;

-(void)checkCommentNotiCount;

- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;
@end
