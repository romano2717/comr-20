//
//  CheckListViewController.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListViewController.h"
#import "Synchronize.h"

@interface CheckListViewController ()

@end

@implementation CheckListViewController

@synthesize blockId,scheduleArrayRaw,selectedCheckList,selectedJobTypes,finishedInspectionResultArray,savedInspectionResultArray,scheduleArray,sectionsArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    check_list = [[Check_list alloc] init];
    schedule = [[Schedule alloc] init];
    
    sectionsArray = [[NSMutableArray alloc] init];
    scheduleArray = [[NSMutableArray alloc] init];
    
    selectedJobTypes = [[NSMutableArray alloc] init];
    selectedCheckList = [[NSMutableArray alloc] init];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self fetchCheckList];
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

- (void)fetchCheckList
{
    //get current updated checlist
    NSArray *updateChecklist = [check_list updatedChecklist];

    [selectedCheckList removeAllObjects];
    [selectedJobTypes removeAllObjects];
    
    for (int i = 0; i < updateChecklist.count; i++) {
        NSDictionary *dict = [updateChecklist objectAtIndex:i];
        NSNumber *ids = [NSNumber numberWithInt:[[dict valueForKey:@"chkAIid"] intValue]];
        [selectedCheckList addObject:ids];
    }
    
    //get all finished schedule and disable their checkboxes
    [finishedInspectionResultArray removeAllObjects];
    finishedInspectionResultArray = nil;
    finishedInspectionResultArray = [[NSMutableArray alloc] init];
    
    NSArray *saved = [check_list inspectionResultCheckListForStatus:[NSNumber numberWithInt:2]];
    for (int i = 0; i < saved.count; i++) {
        NSDictionary *dict = [saved objectAtIndex:i];
        NSNumber *chkAIid = [NSNumber numberWithInt:[[dict valueForKey:@"chkAIid"] intValue]];
        
        [finishedInspectionResultArray addObject:chkAIid];
    }
    
    //get schedule
    scheduleArray = [check_list fetchCheckListForBlockId:blockId];
    scheduleArrayRaw = scheduleArray;
    
    //create sections array and group it!
    [sectionsArray removeAllObjects];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < scheduleArray.count; i++) {
        NSDictionary *dict = [scheduleArray objectAtIndex:i];
        [sectionsArray addObject:[dict valueForKey:@"w_jobtype"]];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[dict valueForKey:@"w_jobtypeId"] intValue]];
        
        [arr addObject:[check_list checklistForJobTypeId:jobTypeId]];
    }
    
    scheduleArray = arr;
    
    
    //set the area
    
    NSString *area = [NSString stringWithFormat:@"Area: %@",[[scheduleArrayRaw lastObject] valueForKey:@"w_area"]];
    
    if(scheduleArray.count == 0)
        area = @"No Schedule for today.";
    
    self.areaLabel.text = area;
    
    [self.checkListTable reloadData];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sectionsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [[scheduleArray objectAtIndex:section] count];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [sectionsArray objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 70.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *cellIdentifier = @"headerCell";
    
    NSDictionary *dict = [scheduleArrayRaw objectAtIndex:section];
    
    CheckListHeader* ch = (CheckListHeader *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    [ch initCellWithResultSet:dict];
    
    //job type toggle
    ch.checkBoxBtn.tag = (int)section;
    [ch.checkBoxBtn addTarget:self action:@selector(toggleJobTypeCheckBox:) forControlEvents:UIControlEventTouchUpInside];
    
    if([selectedJobTypes containsObject:[NSNumber numberWithInt:(int)section]])
    {
        [ch.checkBoxBtn setSelected:YES];
    }
    else
    {
        [ch.checkBoxBtn setSelected:NO];
    }


    //finish and save
    ch.saveBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    [ch.saveBtn addTarget:self action:@selector(saveCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    ch.finishBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    [ch.finishBtn addTarget:self action:@selector(finishCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //jobtype save/finish?

    if([[dict valueForKey:@"w_supflag"] intValue] == 2) //finished
    {
        ch.checkBoxBtn.enabled = NO;
        ch.saveBtn.hidden = YES;
        ch.finishBtn.hidden = YES;
    }

    
    //mark check this section if all contents of checkList is found inside
    NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:section] valueForKey:@"w_jobtypeId"] intValue]] ;
    NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];
    NSMutableArray *checkedIds = [[NSMutableArray alloc] init];
    
    //save only the ids
    for (int i = 0; i < checkList.count; i++) {
        NSNumber *ids = [NSNumber numberWithInt:[[[checkList objectAtIndex:i] valueForKey:@"id"] intValue]];
        [checkedIds addObject:ids];
    }
    
    BOOL found = YES;
    for (int i = 0; i < checkedIds.count; i++) {
        NSNumber *chklst = [checkedIds objectAtIndex:i];
        if([selectedCheckList containsObject:chklst] == NO)
        {
            found = NO;
            break;
        }
        
    }
    
    if(found)
    {
        [ch.checkBoxBtn setSelected:YES];
    }
    
    return ch;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"checkListCell";
    
    CheckListTableViewCell *cell = (CheckListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict = [[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    //[cell initCellWithResultSet:dict];
    
    //set custom views
    cell.checkList.text = [NSString stringWithFormat:@"%@ - %d",[dict valueForKey:@"w_item"],[[dict valueForKey:@"id"] intValue]];

    cell.checkBoxBtn.tag = [[dict valueForKey:@"id"] intValue];
    [cell.checkBoxBtn addTarget:self action:@selector(toggleCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //custom view modifier
    NSNumber *tag = [NSNumber numberWithInt:(int)cell.checkBoxBtn.tag];
    
    if([selectedCheckList containsObject:tag] ==  YES)
    {
        [cell.checkBoxBtn setSelected:YES];
        
        /*
         TODO: use the code below to display finished jobs but disabled checkbox button.
         problem: cell re-use issue shit when modifying checkbox button view.
         */
        
        //is this checklist finished? disable checkbox
//        if([finishedInspectionResultArray containsObject:tag])
//        {
//            DDLogVerbose(@"finishedInspectionResultArray %@",finishedInspectionResultArray);
//            DDLogVerbose(@"section %d",(int)indexPath.section);
//            DDLogVerbose(@"tag %@",tag);
//            DDLogVerbose(@"%@",dict);
//            [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checked@2x"] forState:UIControlStateNormal];
//            cell.checkBoxBtn.enabled = NO;
//            cell.checkBoxBtn.hidden = YES;
//        }
    }
    else
    {
        [cell.checkBoxBtn setSelected:NO];
    }

    return cell;
}

- (IBAction)saveCheckList:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIButton *btn = (UIButton *)sender;

    NSNumber *tappedScheduleId = [NSNumber numberWithInt:(int)btn.tag];
    
    NSArray *arr = [schedule checkListForScheduleId:tappedScheduleId];
    
    //clear ro_inspectionresult first
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        //delete entry for same w_scheduleid and w_checklistid
        BOOL del = [db executeUpdate:@"delete from ro_inspectionresult where w_scheduleid = ?",tappedScheduleId];
       
        if(!del)
        {
            *rollback = YES;
            return;
        }
    }];
    
    for (int i = 0; i < arr.count; i++) {
        NSDictionary *dict = [arr objectAtIndex:i];
        NSNumber *scheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"w_scheduleid"] intValue]];
        NSNumber *checklistId = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
        NSNumber *checkAreaId = [NSNumber numberWithInt:[[dict valueForKey:@"w_checkareaid"] intValue]];
        NSNumber *theChecklistId = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
        
        if([selectedCheckList containsObject:checklistId] == YES && tappedScheduleId == scheduleId)
        {
            BOOL save = [schedule saveOrFinishScheduleWithId:scheduleId checklistId:theChecklistId checkAreaId:checkAreaId withStatus:[NSNumber numberWithInt:1]];
            
            if(!save)
            {
                DDLogVerbose(@"saveCheckList failed");
            }
            else
                DDLogVerbose(@"saveCheckList ok");
        }
    }
    
    [btn setSelected:!btn.selected];
    
    [self fetchCheckList];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Synchronize *sync = [Synchronize sharedManager];
        [sync uploadInspectionResultFromSelf:NO];
    });
}

- (IBAction)finishCheckList:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tappedScheduleId = [NSNumber numberWithInt:(int)btn.tag];
    
    NSArray *arr = [schedule checkListForScheduleId:tappedScheduleId];
    
    //clear ro_inspectionresult first
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = NO;
        //delete entry for same w_scheduleid and w_checklistid
        BOOL del = [db executeUpdate:@"delete from ro_inspectionresult where w_scheduleid = ?",tappedScheduleId];
        
        if(!del)
        {
            *rollback = YES;
            return;
        }
    }];
    
    for (int i = 0; i < arr.count; i++) {
        NSDictionary *dict = [arr objectAtIndex:i];
        NSNumber *scheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"w_scheduleid"] intValue]];
        NSNumber *checklistId = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
        NSNumber *checkAreaId = [NSNumber numberWithInt:[[dict valueForKey:@"w_checkareaid"] intValue]];
        NSNumber *theChecklistId = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
        
        if([selectedCheckList containsObject:checklistId] == YES && tappedScheduleId == scheduleId)
        {
            BOOL save = [schedule saveOrFinishScheduleWithId:scheduleId checklistId:theChecklistId checkAreaId:checkAreaId withStatus:[NSNumber numberWithInt:2]];
            
            if(!save)
            {
                DDLogVerbose(@"saveCheckList failed");
            }
            else
                DDLogVerbose(@"saveCheckList ok");
        }
    }
    
    [btn setSelected:!btn.selected];
    
    [self fetchCheckList];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Synchronize *sync = [Synchronize sharedManager];
        [sync uploadInspectionResultFromSelf:NO];
    });
}

- (IBAction)toggleJobTypeCheckBox:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    [btn setSelected:!btn.selected];
    
    if([selectedJobTypes containsObject:tag] == NO)
    {
        [selectedJobTypes addObject:tag];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:btn.tag] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];

        //check all checklist under this section
        for (int i = 0; i < checkList.count; i++) {
            NSDictionary *dict = [checkList objectAtIndex:i];
            NSNumber *ids = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
            
            if([selectedCheckList containsObject:ids] == NO)
                [selectedCheckList addObject:[NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]]];
        }
    }
    
    else
    {
        [selectedJobTypes removeObject:tag];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:btn.tag] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];
        
        //un-check all checklist under this section
        for (int i = 0; i < checkList.count; i++) {
            NSDictionary *dict = [checkList objectAtIndex:i];
            [selectedCheckList removeObject:[NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]]];
        }
    }
    
    [self.checkListTable reloadData];
}

- (IBAction)toggleCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    [btn setSelected:!btn.selected];
    
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkListTable];
    NSIndexPath *indexPath = [self.checkListTable indexPathForRowAtPoint:buttonOriginInTableView];
    
    if([selectedCheckList containsObject:tag] == NO)
    {
        [selectedCheckList addObject:tag];
        
        //mark check this section if all contents of checkList is found inside
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];
        NSMutableArray *checkedIds = [[NSMutableArray alloc] init];
        
        //save only the ids
        for (int i = 0; i < checkList.count; i++) {
            NSNumber *ids = [NSNumber numberWithInt:[[[checkList objectAtIndex:i] valueForKey:@"id"] intValue]];
            [checkedIds addObject:ids];
        }
        
        BOOL found = YES;
        for (int i = 0; i < checkedIds.count; i++) {
            NSNumber *chklst = [checkedIds objectAtIndex:i];

            if([selectedCheckList containsObject:chklst] == NO)
            {
                found = NO;
                break;
            }
            
        }
        
        if(found)
        {
            [selectedJobTypes addObject:[NSNumber numberWithInt:(int)indexPath.section]];
        }
    }
    else
    {
        [selectedCheckList removeObject:tag];
        
        //un-check the section of this checklist
        CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkListTable];
        NSIndexPath *indexPath = [self.checkListTable indexPathForRowAtPoint:buttonOriginInTableView];
        
        [selectedJobTypes removeObject:[NSNumber numberWithInt:(int)indexPath.section]];
    }
    
    [self.checkListTable reloadData];
}

@end
