//
//  CheckListViewController.h
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Check_list.h"
#import "CheckListTableViewCell.h"
#import "CheckListHeader.h"
#import "Schedule.h"
#import "Database.h"
#import "MBProgressHUD.h"

@interface CheckListViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    Check_list *check_list;
    Schedule *schedule;
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITableView *checkListTable;
@property (nonatomic, weak) IBOutlet UILabel *areaLabel;

@property (nonatomic, strong) NSArray *scheduleArray;
@property (nonatomic, strong) NSArray *scheduleArrayRaw;

@property (nonatomic, strong) NSMutableArray *finishedInspectionResultArray;
@property (nonatomic, strong) NSMutableArray *savedInspectionResultArray;

@property (nonatomic, strong) NSMutableArray *sectionsArray;

@property (nonatomic, strong) NSNumber *blockId;

@property (nonatomic, strong) NSMutableArray *selectedJobTypes;
@property (nonatomic, strong) NSMutableArray *selectedCheckList;


@end
