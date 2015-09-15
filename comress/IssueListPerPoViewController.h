//
//  IssueListPerPoViewController.h
//  comress
//
//  Created by Diffy Romano on 22/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "IssuesTableViewCell.h"
#import "IssuesChatViewController.h"
#import "MZFormSheetController.h"
#import "NavigationBarTitleWithSubtitleView.h"
#import "Database.h"

@interface IssueListPerPoViewController : UIViewController<MZFormSheetBackgroundWindowDelegate,IssuesChatViewControllerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    Post *post;
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITableView *pOIssuesTableView;
@property (nonatomic, strong) NSDictionary *poDict;
@property (nonatomic, strong) NSArray *postsArray;
@end
