//
//  CheckAreaViewController.m
//  comress
//
//  Created by Diffy Romano on 26/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckAreaViewController.h"

@interface CheckAreaViewController ()
{
    BOOL checkBoxModified;
}

@end

@implementation CheckAreaViewController

@synthesize blockId,scheduleArray,sectionsArray,scheduleArrayRaw,selectedJobTypes,selectedCheckAreas,indexPathPerSection,savedCheckList,finishedCheckList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    myDatabase = [Database sharedMyDbManager];
    
    check_area = [[Check_area alloc] init];
    schedule = [[Schedule alloc] init];
    check_list = [[Check_list alloc] init];
    
    selectedJobTypes = [[NSMutableArray alloc] init];
    selectedCheckAreas = [[NSMutableArray alloc] initWithArray:[[NSMutableArray alloc] init]];
    indexPathPerSection = [[NSMutableArray alloc] init];
    
    savedCheckList = [[NSMutableArray alloc] init];
    finishedCheckList = [[NSMutableArray alloc] init];
    
    [self fetchSchedule];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //set the area
    NSString *area = [NSString stringWithFormat:@"Area: %@",[[scheduleArrayRaw lastObject] valueForKey:@"w_area"]];
    
    if(scheduleArray.count == 0)
        area = @"No Schedule for today.";
    
    self.areaLabel.text = area;
    
    [self.checkAreaTable reloadData];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_subCheckList"])
    {
        NSDictionary *dict = (NSDictionary *)sender;
        
        SubCheckListViewController *svc = [segue destinationViewController];
        svc.dict = dict;
    }
}


- (IBAction)viewCheckList:(id)sender
{
    //get jobtypeid and check area id
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkAreaTable];
    NSIndexPath *indexPath = [self.checkAreaTable indexPathForRowAtPoint:buttonOriginInTableView];

    NSNumber *checkAreaId = [NSNumber numberWithInt:[[[[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKey:@"w_chkareaid"] intValue]];
    NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_jobtypeId"] intValue]];
    NSString *checkAreaName = [[[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKey:@"w_chkarea"];
    
    [self performSegueWithIdentifier:@"push_subCheckList" sender:@{@"checkAreaId":checkAreaId,@"jobTypeId":jobTypeId,@"checkAreaName":checkAreaName}];
}

- (void)fetchSchedule
{
    [selectedJobTypes removeAllObjects];
    [selectedCheckAreas removeAllObjects];
    
    scheduleArray = [check_area scheduleForBlock:blockId];
    scheduleArrayRaw = scheduleArray;
    
    //create sections
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < scheduleArray.count; i++) {
        NSDictionary *dict = [scheduleArray objectAtIndex:i];
        [arr addObject:[dict valueForKey:@"w_jobtype"]];
    }
    sectionsArray = arr;
    
    
    //format schedule per section
    NSMutableArray *sked = [[NSMutableArray alloc] init];
    for (int i = 0; i < scheduleArray.count; i++) {
        NSDictionary *dict = [scheduleArray objectAtIndex:i];
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[dict valueForKey:@"w_jobtypeId"] intValue]];
        
        //get the check area of this job type
        NSArray *checkAreaArr = [check_area checkAreaForJobTypeId:jobTypeId];
        [sked addObject:checkAreaArr];
    }
    
    scheduleArray = sked;
    
    
    [self.checkAreaTable reloadData];
    
    
    //save all indexpath per section
    [indexPathPerSection removeAllObjects];
    
    
    for (int i = 0; i < sectionsArray.count; i++) {
        
        NSInteger rows = [self.checkAreaTable numberOfRowsInSection:i];
        NSMutableArray *indexPathsArr = [[NSMutableArray alloc] init];
        for (int x = 0; x < rows; x ++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:x inSection:i];
            [indexPathsArr addObject:indexPath];
        }
        
        [indexPathPerSection addObject:indexPathsArr];
    }
    
    DDLogVerbose(@"indexPathInThisSection %@",indexPathPerSection);
}

#pragma mark - uitableview delegate and datasource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [sectionsArray objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 70.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[scheduleArray objectAtIndex:section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *cellIdentifier = @"skedCell";
    
    NSDictionary *dict = [scheduleArrayRaw objectAtIndex:section];

    CheckAreaHeader *cah = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    [cah initCellWithResultSet:dict];
    
    if(checkBoxModified == NO)
    {
        if([[dict valueForKey:@"w_supflag"] intValue] == 1 || [[dict valueForKey:@"w_flag"] intValue] == 1)
        {
            [selectedJobTypes addObject:[NSNumber numberWithInt:(int)section]];
        }
    }
    
    //job type toggle
    cah.checkBoxBtn.tag = (int)section;
    [cah.checkBoxBtn addTarget:self action:@selector(toggleJobTypeCheckBox:) forControlEvents:UIControlEventTouchUpInside];
    

    //finish and save
    cah.saveBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    cah.finishBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    
    [cah.saveBtn addTarget:self action:@selector(saveTheCheckList:) forControlEvents:UIControlEventTouchUpInside];
    [cah.finishBtn addTarget:self action:@selector(finishTheCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    //if all checkboxes are checked under this section, check the job type
    NSArray *indexPathInSection = [indexPathPerSection objectAtIndex:section];
    BOOL found = YES;
    for (int i = 0; i < indexPathInSection.count; i++) {
        NSIndexPath *indexPath = [indexPathInSection objectAtIndex:i];
        if([selectedCheckAreas containsObject:indexPath])
            found = YES;
        else
        {
            found = NO;
            break;
        }
    }
    
    if(found)
        [selectedJobTypes addObject:[NSNumber numberWithInt:(int)section]];

    
    //set checkbox
    if([selectedJobTypes containsObject:[NSNumber numberWithInt:(int)section]] == YES)
        [cah.checkBoxBtn setSelected:YES];
    

    return cah;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIndentifier = @"chkListCell";
    
    CheckListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier forIndexPath:indexPath];
    NSDictionary *dict = [[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSDictionary *topDict = [scheduleArrayRaw objectAtIndex:indexPath.section];
    
    [cell initCellWithResultSet:dict];
    
    [cell.checkBoxBtn addTarget:self action:@selector(toggleCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.checkListBtn addTarget:self action:@selector(viewCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    //db reference
    if(checkBoxModified == NO)
    {
        int w_flag = [[topDict valueForKey:@"w_flag"] intValue];
        int w_supflag = [[topDict valueForKey:@"w_supflag"] intValue];
        
        if(w_flag > 0 || w_supflag > 0)
        {
            [selectedCheckAreas addObject:indexPath];
        }
    }
    
    //modify checkbox
    if([selectedCheckAreas containsObject:indexPath] == YES)
    {
        [cell.checkBoxBtn setSelected:YES];
    }
    else
        [cell.checkBoxBtn setSelected:NO];
    

    return cell;
}

- (IBAction)toggleJobTypeCheckBox:(id)sender
{
    checkBoxModified = YES;
    
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];

    [btn setSelected:!btn.selected];
    
    //clear everything first
    //un-check all checkboxes under this section
    NSInteger rows = [self.checkAreaTable numberOfRowsInSection:[tag intValue]];
    
    for (int i = 0; i < rows; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:[tag intValue]];
        
        [selectedCheckAreas removeObject:indexPath];
    }
    
    
    if([selectedJobTypes containsObject:tag] == NO)
    {
        [selectedJobTypes addObject:tag];
        
        //check all checkboxes under this section
        NSInteger rows = [self.checkAreaTable numberOfRowsInSection:[tag intValue]];
        
        for (int i = 0; i < rows; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:[tag intValue]];
            
            if([selectedCheckAreas containsObject:indexPath] == NO)
            {
                [selectedCheckAreas addObject:indexPath];
            }
            else
            {
                [selectedCheckAreas removeObject:indexPath];
            }
        }
    }
    
    else
    {
        [selectedJobTypes removeObject:tag];
        
        
        //un-check all checkboxes under this section
        NSInteger rows = [self.checkAreaTable numberOfRowsInSection:[tag intValue]];
        
        for (int i = 0; i < rows; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:[tag intValue]];
            
            [selectedCheckAreas removeObject:indexPath];
        }
    }
    
    [self.checkAreaTable reloadData];
}


- (IBAction)toggleCheckList:(id)sender
{
    checkBoxModified = YES;
    
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkAreaTable];
    NSIndexPath *indexPath = [self.checkAreaTable indexPathForRowAtPoint:buttonOriginInTableView];
    
    if([selectedCheckAreas containsObject:indexPath] == NO)
    {
        [selectedCheckAreas addObject:indexPath];
    }
    else
    {
        [selectedCheckAreas removeObject:indexPath];
    }
    
    //if all checkboxes are checked under this section, check the job type
    NSArray *indexPathInSection = [indexPathPerSection objectAtIndex:indexPath.section];
    BOOL found = YES;
    for (int i = 0; i < indexPathInSection.count; i++) {
        NSIndexPath *indexPath = [indexPathInSection objectAtIndex:i];
        if([selectedCheckAreas containsObject:indexPath])
            found = YES;
        else
        {
            found = NO;
            break;
        }
    }

    if(found)
        [selectedJobTypes addObject:[NSNumber numberWithInt:(int)indexPath.section]];
    else
        [selectedJobTypes removeObject:[NSNumber numberWithInt:(int)indexPath.section]];
    
    
    [self.checkAreaTable reloadData];
}

- (IBAction)saveTheCheckList:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tappedScheduleId = [NSNumber numberWithInt:(int)btn.tag];
    
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


    for (int i = 0; i < selectedCheckAreas.count; i++) {
        
        NSIndexPath *indexPath = (NSIndexPath *)[selectedCheckAreas objectAtIndex:i];
        
        CheckListCell *cell = (CheckListCell *)[self.checkAreaTable cellForRowAtIndexPath:indexPath];
        
        NSNumber *w_chkareaid = [NSNumber numberWithInt:(int)cell.checkBoxBtn.tag];
        NSNumber *scheduleId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_scheduleid"] intValue]];
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_jobtypeId"] intValue]];
        
        NSArray *checkList = [check_list checkListForCheckAreaId:w_chkareaid JobTypeId:jobTypeId];
        
        for (int j = 0; j < checkList.count; j++) {
            NSNumber *checkListId = [[checkList objectAtIndex:j] valueForKey:@"w_chklistid"];
            
            BOOL save = [schedule saveOrFinishScheduleWithId2:scheduleId checklistId:checkListId checkAreaId:w_chkareaid withStatus:[NSNumber numberWithInt:1]];
            
            if(!save)
            {
                DDLogVerbose(@"checklist save fail for scheduleId %@, w_chkareaid %@, jobTypeId %@ checkListId %@",scheduleId,w_chkareaid,jobTypeId,checkListId);
            }
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}


- (IBAction)finishTheCheckList:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tappedScheduleId = [NSNumber numberWithInt:(int)btn.tag];
    
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
    
    
    for (int i = 0; i < selectedCheckAreas.count; i++) {
        
        NSIndexPath *indexPath = (NSIndexPath *)[selectedCheckAreas objectAtIndex:i];
        
        CheckListCell *cell = (CheckListCell *)[self.checkAreaTable cellForRowAtIndexPath:indexPath];
        
        NSNumber *w_chkareaid = [NSNumber numberWithInt:(int)cell.checkBoxBtn.tag];
        NSNumber *scheduleId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_scheduleid"] intValue]];
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_jobtypeId"] intValue]];
        
        NSArray *checkList = [check_list checkListForCheckAreaId:w_chkareaid JobTypeId:jobTypeId];
        
        for (int j = 0; j < checkList.count; j++) {
            NSNumber *checkListId = [[checkList objectAtIndex:j] valueForKey:@"w_chklistid"];
            
            BOOL save = [schedule saveOrFinishScheduleWithId2:scheduleId checklistId:checkListId checkAreaId:w_chkareaid withStatus:[NSNumber numberWithInt:2]];
            
            if(!save)
            {
                DDLogVerbose(@"checklist save fail for scheduleId %@, w_chkareaid %@, jobTypeId %@ checkListId %@",scheduleId,w_chkareaid,jobTypeId,checkListId);
            }
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    [self fetchSchedule];
}



@end
