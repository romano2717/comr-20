//
//  BlockScheduleListViewController.m
//  comress
//
//  Created by Diffy Romano on 2/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "BlockScheduleListViewController.h"

@interface BlockScheduleListViewController ()<UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, strong) NSArray *blockScheduleArray;
@property (nonatomic, strong) NSDate *currentlySelectedDate;

@property (nonatomic, weak) IBOutlet STCollapseTableView *blockScheduleTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, assign) BOOL didNavigateAwayFromView;

@property (nonatomic, strong) NSArray *sectionHeaders;

@property (nonatomic, assign) NSInteger previouslyOpenSection;

@end



@implementation BlockScheduleListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    routineSync = [RoutineSynchronize sharedRoutineSyncManager];
    
    myBlocks = [[Blocks alloc] init];
    
    _blockScheduleTableView.estimatedRowHeight = 98;
    _blockScheduleTableView.rowHeight = UITableViewAutomaticDimension;
    
    [_blockScheduleTableView setExclusiveSections:YES];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScanQrCodePerBlock:) name:@"didScanQrCodePerBlock" object:nil];
    
    [self getCurrentDaySchedule];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadScheduleList];
}

- (void)reloadScheduleList
{
    [_blockScheduleTableView reloadData];
    
    if(_didNavigateAwayFromView == NO)
        [_blockScheduleTableView setContentOffset:CGPointZero animated:YES];
    
    [_blockScheduleTableView openSection:_previouslyOpenSection animated:NO];
}

- (IBAction)gotoJobListForBlock:(UIButton *)sender
{
    _didNavigateAwayFromView = YES;
    
    NSIndexPath *indexPath = [_blockScheduleTableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    
    [self performSegueWithIdentifier:@"push_jobs" sender:indexPath];
}

#pragma mark  qr code scanning

- (IBAction)scanQrCode:(UIButton *)sender
{
    _didNavigateAwayFromView = YES;
    NSIndexPath *indexPath = [_blockScheduleTableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    
    if(sender.tag == 0)
    {
        [self performSegueWithIdentifier:@"push_qr_scan" sender:indexPath];
    }
    else if (sender.tag == 1)
    {
        [self performSegueWithIdentifier:@"push_jobs" sender:indexPath];
    }
}

- (void)didScanQrCodePerBlock:(NSNotification *)notif
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDictionary *dict = [notif userInfo];
        
        CLLocation *location = [dict objectForKey:@"location"];
        
        NSString *barCodeValue = [dict valueForKey:@"scanValue"];
        
        if(barCodeValue.length == 0)
            return;
        
        NSNumber *longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
        NSNumber *latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
        NSNumber *blkId = [NSNumber numberWithInt:[[[dict objectForKey:@"scheduleDict"] valueForKey:@"blk_id"] intValue]];
        NSNumber *scheduleDate = [NSNumber numberWithDouble:[[[dict objectForKey:@"scheduleDict"] valueForKey:@"ScheduledDate"] doubleValue]];
        
        NSNumber *one = [NSNumber numberWithInt:1];
        
        BOOL ups = [db executeUpdate:@"update rt_blk_schedule set barcode = ?, latitude = ?, longitude = ?, unlock = ?, sync_flag = ? where blk_id = ? and schedule_date = ?",barCodeValue,latitude,longitude,one,one,blkId,scheduleDate];
        
        if(!ups)
        {
            *rollback = YES;
            return;
        }
    }];
    
    [routineSync uploadUnlockBlockInfoFromSelf:NO];
    
    [self getCurrentDaySchedule];
}

- (void)getCurrentDaySchedule
{
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *nowDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:24*00*00];
    
    _currentlySelectedDate = nowDate;
    
    [self downloadBlockScheduleForDate:nowDate];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"push_qr_scan"])
    {
        NSDictionary *dict;
        
        NSIndexPath *indexPath = sender;
        
        if(self.segment.selectedSegmentIndex == 0)
            dict = [_blockScheduleArray objectAtIndex:indexPath.row];
        else
            dict = [[_blockScheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        QRCodeScanningViewController *qrCodeScan = [segue destinationViewController];
        qrCodeScan.scheduleDetailDict = dict;
    }
    
    else if ([segue.identifier isEqualToString:@"push_jobs"])
    {
        NSDictionary *dict;
        
        NSIndexPath *indexPath = sender;
        
        if(self.segment.selectedSegmentIndex == 0)
            dict = [_blockScheduleArray objectAtIndex:indexPath.row];
        else
            dict = [[_blockScheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        JobListViewController *jobsList = [segue destinationViewController];
        jobsList.scheduleDetailDict = dict;
    }
}


-(IBAction)segmentControlChange:(id)sender
{
    _previouslyOpenSection = 0;
    _sectionHeaders = nil;
    
    [self downloadBlockScheduleForDate:_currentlySelectedDate];
}

- (IBAction)toggleCalendar:(id)sender
{
    [ActionSheetDatePicker showPickerWithTitle:@"Date" datePickerMode:UIDatePickerModeDate selectedDate:_currentlySelectedDate minimumDate:[NSDate date] maximumDate:nil doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
        
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:selectedDate];
        selectedDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:24*00*00];
        
        _currentlySelectedDate = selectedDate;
        
        _didNavigateAwayFromView = NO;
        
        [self downloadBlockScheduleForDate:selectedDate];
        
    } cancelBlock:^(ActionSheetDatePicker *picker) {
        
    } origin:sender];
}

- (BOOL)retrieveScheduleLocallyForDate:(NSDate *)date
{
    //retrieve from local db
    __block BOOL scheduleisExists = NO;
    
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *nowDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:24*00*00];
    
    NSNumber *scheduleDateEpoch = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    NSNumber *nowDateEpoch = [NSNumber numberWithDouble:[nowDate timeIntervalSince1970]];
    
    NSString *userId = [NSString stringWithFormat:@"%@",[myDatabase.userDictionary valueForKey:@"user_id"]];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        /*******/
//        [db executeUpdate:@"delete from rt_blk_schedule_sync"];
//        [db executeUpdate:@"delete from rt_blk_schedule"];
        /*******/
        
        
        FMResultSet *rsCheck = [db executeQuery:@"select schedule_date from rt_blk_schedule_sync where schedule_date = ? and download_time = ? and user_id = ?",scheduleDateEpoch,nowDateEpoch,userId];
        
        if([rsCheck next])
            scheduleisExists = YES;
        
        NSMutableArray *blockSchedArr = [[NSMutableArray alloc] init];
        
        if(scheduleisExists)
        {
            NSString *q = [NSString stringWithFormat:@"select (b.block_no || ' ' || b.street_name) as blockDesc, bs.noti_message as Noti, bs.no_of_job as TotalJob, bs.blk_id,bs.unlock as IsUnlock, bm.block_id,bm.user_id, bs.schedule_date as ScheduledDate from rt_blk_schedule bs left join blocks b on bs.blk_id = b.block_id left join block_user_mapping bm on bs.blk_id = bm.block_id where schedule_date = %@ and bs.user_id = '%@' and bm.user_id = '%@' order by schedule_date asc",scheduleDateEpoch,userId,userId];

            if(self.segment.selectedSegmentIndex == 1)
            {
                q = [NSString stringWithFormat:@"select (b.block_no || ' ' || b.street_name) as blockDesc, bs.noti_message as Noti, bs.no_of_job as TotalJob, bs.blk_id,bs.unlock as IsUnlock, bm.block_id,bm.user_id, bs.schedule_date as ScheduledDate from rt_blk_schedule bs left join blocks b on bs.blk_id = b.block_id left join block_user_mapping bm on bs.blk_id = bm.block_id where schedule_date = %@ and bs.user_id = '%@' and bm.user_id != '%@' order by schedule_date asc",scheduleDateEpoch,userId,userId];
            }
            FMResultSet *rsSked = [db executeQuery:q];

            while ([rsSked next]) {
                [blockSchedArr addObject:[rsSked resultDictionary]];
            }
            
            _blockScheduleArray = blockSchedArr;
            
            if(self.segment.selectedSegmentIndex == 1)
                [self groupScheduleForOthers];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self reloadScheduleList];
            });
        }
    }];
    
    return scheduleisExists;
}

- (void)downloadBlockScheduleForDate:(NSDate *)date
{
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *nowDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:24*00*00];
    
    NSNumber *scheduleDateEpoch = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    
    NSString *userId = [NSString stringWithFormat:@"%@",[myDatabase.userDictionary valueForKey:@"user_id"]];
    
    
    //retrieve from local db
    if([self retrieveScheduleLocallyForDate:date] == NO)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL del = [db executeUpdate:@"delete from rt_blk_schedule where schedule_date = ? and user_id = ?",scheduleDateEpoch,userId];
            if(!del)
            {
                *rollback = YES;
                return;
            }
            
            BOOL del2 = [db executeUpdate:@"delete from rt_blk_schedule_sync where schedule_date = ? and user_id = ?",scheduleDateEpoch,userId];
            if(!del2)
            {
                *rollback = YES;
                return;
            }
        }];
        
        //download new schedule
        
        NSString *wcfDate = [myDatabase createWcfDateWithNsDate:date];
        
        NSDictionary *params = @{@"scheduledDate":wcfDate};
        
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_download_block_schedule] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSArray *ScheduledBlockList = [responseObject objectForKey:@"ScheduledBlockList"];
            
            NSMutableArray *blockSchedArr = [[NSMutableArray alloc] init];
            
            _blockScheduleArray = nil;
            
            NSDate *schedule_date;
            NSString *userId = [NSString stringWithFormat:@"%@",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            for (int i = 0 ; i < ScheduledBlockList.count; i++) {
                NSDictionary *dict = [ScheduledBlockList objectAtIndex:i];
                
                NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                
                NSNumber *blockId = [NSNumber numberWithInt:[[dict valueForKey:@"BlkId"] intValue]];
                
                NSDictionary *blockDict = [[myBlocks fetchBlocksWithBlockId:blockId] firstObject];
                
                NSString *blockDesc = [NSString stringWithFormat:@"%@ %@",[blockDict valueForKey:@"block_no"],[blockDict valueForKey:@"street_name"]];
                
                [mutDict setObject:blockDesc forKey:@"blockDesc"];
                
                [blockSchedArr addObject:mutDict];
                
                
                schedule_date = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"ScheduledDate"]];
                
                //save the schedule to local table
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    BOOL ins = [db executeUpdate:@"insert into rt_blk_schedule(blk_id, no_of_job, schedule_date, unlock, noti_message, sync_flag, user_id) values (?,?,?,?,?,?,?)",blockId,[NSNumber numberWithInt:[[dict valueForKey:@"TotalJob"] intValue]],schedule_date,[NSNumber numberWithBool:[[dict valueForKey:@"IsUnlock"] boolValue]],[dict valueForKey:@"Noti"],[NSNumber numberWithInt:0],userId];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
            
            //insert to sked sync
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                BOOL insSync = [db executeUpdate:@"insert into rt_blk_schedule_sync(schedule_date, download_time, user_id) values (?,?,?)",schedule_date,nowDate,userId];
                
                if(!insSync)
                {
                    *rollback = YES;
                    return;
                }
            }];
            
            if(ScheduledBlockList.count > 0)
                [self retrieveScheduleLocallyForDate:date];
            else
            {
                [self getCurrentDaySchedule];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self downloadBlockScheduleForDate:date];
        }];
    }
}

- (void)groupScheduleForOthers
{
    NSArray *otherUsersArray = [_blockScheduleArray valueForKey:@"user_id"];
    otherUsersArray = [[NSSet setWithArray:otherUsersArray] allObjects];
    
    _sectionHeaders = otherUsersArray;

    NSMutableArray *scheduleTemp = [[NSMutableArray alloc] init];
    
    for (NSString *section in _sectionHeaders) {
        
        NSMutableArray *rowsPerSection = [[NSMutableArray alloc] init];
        
        for (NSDictionary *dict in _blockScheduleArray) {
            if([[dict valueForKey:@"user_id"] isEqualToString:section])
            {
                if([rowsPerSection containsObject:dict] == NO)
                    [rowsPerSection addObject:dict];
            }
        }
        
        [scheduleTemp addObject:rowsPerSection];
    }
    
    _blockScheduleArray = scheduleTemp;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 1)
        return [_sectionHeaders objectAtIndex:section];
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(_sectionHeaders.count == 1)
        return 42.0f;
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(self.sectionHeaders.count == 1)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        btn.frame = CGRectMake(0, 0, self.view.frame.size.width, 42.0f);
        [btn setTitle:[self.sectionHeaders objectAtIndex:section] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor lightGrayColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        btn.tag = section;
        [btn.layer setBorderWidth:0.5f];
        [btn.layer setBorderColor:[UIColor whiteColor].CGColor];
        
        return btn;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    if(self.segment.selectedSegmentIndex == 0)
        return 1;
    else
        return _sectionHeaders.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    if(self.segment.selectedSegmentIndex == 0)
        return _blockScheduleArray.count;
    
    return [[_blockScheduleArray objectAtIndex:section] count];
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     
     static NSString *cellIdentifier = @"cell";
     
     BlockSchedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
     
     NSDictionary *dict;
     
     if(self.segment.selectedSegmentIndex == 0)
         dict = [_blockScheduleArray objectAtIndex:indexPath.row];
     
     else if(self.segment.selectedSegmentIndex == 1)
         dict = [[_blockScheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
     
     [cell initCellWithResultSet:dict];
 
     return cell;
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _previouslyOpenSection = indexPath.section;
    
    _didNavigateAwayFromView = YES;
    
    NSDictionary *dict;
    
    if(self.segment.selectedSegmentIndex == 0)
        dict = [_blockScheduleArray objectAtIndex:indexPath.row];
    else
        dict = [[_blockScheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if([[dict valueForKey:@"IsUnlock"] boolValue] == YES)
        [self performSegueWithIdentifier:@"push_jobs" sender:indexPath];
}
@end
