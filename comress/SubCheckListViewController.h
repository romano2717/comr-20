//
//  SubCheckListViewController.h
//  comress
//
//  Created by Diffy Romano on 28/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Check_list.h"
#import "SubCheckListTableViewCell.h"

@interface SubCheckListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Check_list *check_list;
}

@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, strong) NSArray *checkListArray;
@property (nonatomic, weak) IBOutlet UITableView *checkListableView;
@property (nonatomic, strong) NSArray *updatedCheckList;

@property (nonatomic, strong) NSMutableArray *selectedCheckList;

@end
