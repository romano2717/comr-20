//
//  PostStatusTableViewController.h
//  comress
//
//  Created by Diffy Romano on 15/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@class IssuesChatViewController;

@interface PostStatusTableViewController : UITableViewController
{
    Post *post;
}

@property (nonatomic, assign) IssuesChatViewController *delegate;
@property (nonatomic, assign) NSNumber *selectedStatus;
@property (nonatomic) BOOL actionsAreRequired;

@end
