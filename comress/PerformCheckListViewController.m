//
//  PerformCheckListViewController.m
//  comress
//
//  Created by Diffy Romano on 16/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PerformCheckListViewController.h"

@interface PerformCheckListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *checkListTableView;
@property (nonatomic, weak) IBOutlet UIButton *checkAllBtn;

@property (nonatomic, strong) NSArray *checkListArray;
@property (nonatomic, strong) NSMutableArray *checkedCheckListArray;

@property (nonatomic) BOOL checkListWasModified;

@end

@implementation PerformCheckListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    routineSync = [RoutineSynchronize sharedRoutineSyncManager];
    
    _checkListArray = [_scheduleDict objectForKey:@"CheckListArray"];
    _checkedCheckListArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < _checkListArray.count; i++) {
        
        NSDictionary *dict = [_checkListArray objectAtIndex:i];
        
        BOOL IsCheck = [[dict valueForKey:@"IsCheck"] boolValue];
        
        if(IsCheck)
            [_checkedCheckListArray addObject:[NSNumber numberWithInt:i]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return _checkListArray.count;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     static NSString *cellIdentifier = @"cell";
     
     CheckListCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
     
     NSDictionary *dict = @{@"checkListArray":[_checkListArray objectAtIndex:indexPath.row],@"checked":_checkedCheckListArray,@"indexPath":indexPath,@"checkListWasModified":[NSNumber numberWithBool:_checkListWasModified]};
     
     [cell initCellWithResultSet:dict];
     
     return cell;
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCheckList" object:nil userInfo:@{@"checkeCheckList":_checkedCheckListArray}];
}

- (IBAction)cancel:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCheckList" object:nil userInfo:nil];
}

- (IBAction)save:(id)sender
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL up = NO;
        NSNumber *scheduleId = [NSNumber numberWithInt:[[_scheduleDict valueForKeyPath:@"SUPSchedule.ScheduleId"] intValue]];
        
        for (int i = 0; i < _checkListArray.count; i++) {
            NSDictionary *dict = [_checkListArray objectAtIndex:i];
            
            NSNumber *row = [NSNumber numberWithInt:i];
            
            BOOL toggle = YES;
            

            NSNumber *checkListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
            
            if([_checkedCheckListArray containsObject:row] == YES)
                toggle = YES;
            else
                toggle = NO;
            
            NSNumber *toggleBool = [NSNumber numberWithBool:toggle];
            
            up = [db executeUpdate:@"update rt_checklist set is_checked = ? where checklist_id = ? and schedule_id = ?",toggleBool,checkListId,scheduleId];
            
            if(!up)
            {
                *rollback = YES;
                return;
            }
        }
        
        if(up == YES)
        {
            NSNumber *needToSync = [NSNumber numberWithInt:2];
            
            BOOL up2 = [db executeUpdate:@"update rt_schedule_detail set checklist_sync_flag = ? where schedule_id",needToSync,scheduleId];
            
            if(!up2)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCheckList" object:nil userInfo:@{@"checkeCheckList":_checkedCheckListArray}];
}
 

- (IBAction)checkAll:(id)sender
{
    _checkListWasModified = YES;
    
    _checkAllBtn.selected = !_checkAllBtn.selected;
    
    [_checkedCheckListArray removeAllObjects];
    
    if(_checkAllBtn.selected)
    {
        for (int i = 0; i < _checkListArray.count; i++) {
            [_checkedCheckListArray addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    [_checkListTableView reloadData];
}

- (IBAction)toggleCheckList:(id)sender
{
    _checkListWasModified = YES;

    UIButton *btn = sender;
    
    btn.selected = !btn.selected;
    
    int tag = (int)btn.tag;
    
    NSNumber *checkListRow = [NSNumber numberWithInt:tag];
    
    [_checkedCheckListArray removeObject:checkListRow];
    
    if(btn.selected && [_checkedCheckListArray containsObject:checkListRow] == NO)
        [_checkedCheckListArray addObject:checkListRow];
    
    [_checkListTableView reloadData];
    
    if(_checkedCheckListArray.count == _checkListArray.count)
        [self checkAll:sender];
    else
        _checkAllBtn.selected = NO;
}


@end
