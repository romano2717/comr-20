//
//  CheckAreaViewController.h
//  comress
//
//  Created by Diffy Romano on 26/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListCell.h"
#import "Check_area.h"
#import "CheckAreaHeader.h"
#import "MBProgressHUD.h"
#import "Database.h"
#import "Schedule.h"
#import "Check_list.h"
#import "SubCheckListViewController.h"

@interface CheckAreaViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Check_area *check_area;
    Database *myDatabase;
    Schedule *schedule;
    Check_list *check_list;

}
@property (nonatomic, weak) IBOutlet UITableView *checkAreaTable;
@property (nonatomic, weak) IBOutlet UILabel *areaLabel;
@property (nonatomic, strong) NSNumber *blockId;

@property (nonatomic, strong) NSArray *scheduleArray;
@property (nonatomic, strong) NSArray *scheduleArrayRaw;
@property (nonatomic, strong) NSArray *sectionsArray;

@property (nonatomic, strong) NSMutableArray *selectedJobTypes;
@property (nonatomic, strong) NSMutableArray *selectedCheckAreas;
@property (nonatomic, strong) NSMutableArray *indexPathPerSection;

@property (nonatomic, strong) NSMutableArray *savedCheckList;
@property (nonatomic, strong) NSMutableArray *finishedCheckList;

@end
