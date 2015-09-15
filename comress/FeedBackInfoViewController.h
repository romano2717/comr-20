//
//  FeedBackInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Feedback.h"
#import "Contract_type.h"
#import "IssuesChatViewController.h"

@interface FeedBackInfoViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Database *myDatabase;
    Contract_type *contract_type;
}

@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedBackLabel;

@property (nonatomic, weak) IBOutlet UILabel *issueTypeLabel;

@property (nonatomic, weak) IBOutlet UITableView *tableView;


@property (nonatomic, strong) NSNumber *feedbackId;
@property (nonatomic, strong) NSNumber *clientfeedbackId;

@property (nonatomic, strong) NSMutableDictionary *feedbackDict;

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSArray *issueStatus;
@property (nonatomic, strong) NSArray *cmrStatus;

@property (nonatomic) BOOL cameFromChat;

@end
