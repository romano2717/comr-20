//
//  CloseIssueActionViewController.h
//  comress
//
//  Created by Diffy Romano on 11/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloseIssueActionViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextView *remarksTextView;
@property (nonatomic, strong) NSMutableArray *selectedActionsArray;
@property (nonatomic, strong) NSArray *actions;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) int status;
@property (nonatomic) int calledFromList;
@property (nonatomic, strong) NSDictionary *dict;

@end
