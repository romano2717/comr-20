//
//  RoutineChatViewController.h
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "JSQMessagesViewController.h"
#import "JSQMessage.h"
#import "MessageDataRoutine.h"
#import "CheckListViewController.h"
#import "NavigationBarTitleWithSubtitleView.h"
#import "CheckListViewController.h"
#import "FPPopoverKeyboardResponsiveController.h"
#import "Post.h"
#import "Blocks.h"
#import "Database.h"
#import "Synchronize.h"
#import "Users.h"
#import "Comment.h"
#import "NSDate+HumanizedTime.h"
#import "ImagePreviewViewController.h"
#import "MBProgressHUD.h"
#import "CheckAreaViewController.h"

@class RoutineChatViewController;

@protocol IssuesChatViewControllerDelegate <NSObject>

- (void)didDismissJSQMessageComposerViewController:(RoutineChatViewController *)vc;

@end

@interface RoutineChatViewController : JSQMessagesViewController<UIActionSheetDelegate,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate>
{
    FPPopoverKeyboardResponsiveController *popover;
    Post *post;
    Blocks *blocks;
    Database *myDatabase;
    Users *user;
    Comment *comment;
    ImageOptions *imgOpts;
    CLLocationManager *locationManager;    
}

@property (nonatomic, strong) NSString *blockNo;
@property (nonatomic, strong) NSNumber *blockId;
@property (nonatomic, strong) MessageDataRoutine *messageData;
@property (nonatomic) int postId;
@property (nonatomic) int ServerPostId;
@property (nonatomic, strong) NSDictionary *postDict;
@property (nonatomic, strong) NSDictionary *postInfoDict;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) NSArray *commentsArray;
@property (nonatomic) BOOL isFiltered;

@end
