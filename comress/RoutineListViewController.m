//
//  RoutineListViewController.m
//  comress
//
//  Created by Diffy Romano on 11/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineListViewController.h"


@interface RoutineListViewController ()
{
    int currentNumberOfRows;
    int per_page;
    CGPoint currentPoint;
    int lastRow;
}


@end

@implementation RoutineListViewController

@synthesize scheduleArray,sectionsArray,postInfoArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    post = [[Post alloc] init];
    
    sectionsArray = [NSArray arrayWithObjects:@"Active",@"Inactive", nil];
    
    schedule = [[Schedule alloc] init];
    
    //for qr code scanning
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(waitingForLocation) name:@"waitingForLocation" object:self];
    
    
    //when unlock/lock/report button is tapped
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tappedUnlockButton:) name:@"tappedUnlockButton" object:nil];
    
    self.scrollToTopBtn.hidden = YES;
}

- (void)tappedUnlockButton:(NSNotification *)notif
{
    DDLogVerbose(@"sched %@",[[notif userInfo] valueForKey:@"scheduleId"]);
}


- (void)waitingForLocation
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Capturing location...";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanningQrCodeComplete:) name:@"scanningQrCodeComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locatingComplete:) name:@"locatingComplete" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    self.hidesBottomBarWhenPushed = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    currentNumberOfRows = 30;
    per_page = 30;
    
    [self fetchSchedule];
    
}

- (void)addLoadMoreView:(BOOL)moreRows
{
    NSString *msg = @"Drag to load more";
    
    if(!moreRows)
        msg = @"Last row";

    //remove previously added load more view
    for (UIView *view in [self.routineTableView subviews]) {
        if(view.tag == 27)
        {
            [view removeFromSuperview];
        }
    }
    
    //add the view
    UILabel *loadMore = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, self.routineTableView.contentSize.height, 320.0f, 60)];
    loadMore.text = msg;
    loadMore.backgroundColor = [UIColor lightGrayColor];
    loadMore.tag = 27;
    
    [self.routineTableView addSubview:loadMore];
}

- (void)scanningQrCodeComplete:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    [self passQrCodeAndLocation:dict];
}

- (void)locatingComplete:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    [self passQrCodeAndLocation:dict];
}

- (void)passQrCodeAndLocation:(NSDictionary *)dict
{
    CLLocation *location = (CLLocation *)[dict objectForKey:@"location"];
    NSString *scanValue = [dict valueForKey:@"scanValue"];
    
    if(location != nil && scanValue != nil && [location isEqual:[NSNull null]] == NO && [scanValue isEqual:[NSNull null]] == NO)
    {
        DDLogVerbose(@"pass qr code: %@",scanValue);
        DDLogVerbose(@"pass location: %@",location);
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Capturing location...";
        
        [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"scan: %@, loc: %@",scanValue,location]];
    }
    else
    {
        if(location == nil || [location isEqual:[NSNull null]] == YES)
        {
            [myDatabase alertMessageWithMessage:@"Unable to find your location. Please try again."];
        }
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    self.tabBarController.tabBar.hidden = YES;
    self.hidesBottomBarWhenPushed = YES;
    self.navigationController.navigationBar.hidden = NO;
    
    
    if([segue.identifier isEqualToString:@"push_chat_routine"])
    {
        if([sender isKindOfClass:[NSIndexPath class]])
        {
            NSIndexPath *indexPath = (NSIndexPath *)sender;
            
            NSDictionary *skedDict;
            
            if(self.segment.selectedSegmentIndex == 1)
                skedDict = [[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            else
                skedDict = [scheduleArray objectAtIndex:indexPath.row];
            
            NSString *blockNo = [skedDict valueForKey:@"block_no"];
            NSNumber *blockId = [NSNumber numberWithInt:[[skedDict valueForKey:@"block_id"] intValue]];
            
            BOOL isFiltered = NO;
            
            if(self.segment.selectedSegmentIndex == 0)
                isFiltered = YES;
            
            RoutineChatViewController *rtc = [segue destinationViewController];
            rtc.blockNo = blockNo;
            rtc.blockId = blockId;
            rtc.isFiltered = isFiltered;
            rtc = segue.destinationViewController;
            
        }
    }
}


- (IBAction)segmentControlChange:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    self.segment = segment;
    
    [self fetchSchedule];
}

- (void)fetchSchedule
{
    if(self.segment.selectedSegmentIndex == 0)
        scheduleArray = [schedule fetchScheduleForMe];
    else
    {
        scheduleArray = [schedule fetchScheduleForOthersAtPage3:[NSNumber numberWithInt:currentNumberOfRows]];
        
        NSDictionary *topDict = [scheduleArray firstObject];
        
        NSDictionary *activeSked = [topDict objectForKey:@"active"];
        NSDictionary *inactiveSked = [topDict objectForKey:@"inactive"];
        
        NSArray *newSkedArrFormat = [NSArray arrayWithObjects:activeSked,inactiveSked, nil];
        
        scheduleArray = newSkedArrFormat;
    }
    
    
    [self.routineTableView reloadData];
    
    if(self.segment.selectedSegmentIndex == 1)
    {
        [self addLoadMoreView:YES];
        self.scrollToTopBtn.hidden = NO;
    }
    else
        self.scrollToTopBtn.hidden = YES;
    
    [self postInformation];
}

- (void)postInformation
{
    NSMutableArray *postsArr = [[NSMutableArray alloc] init];
    
    if(self.segment.selectedSegmentIndex == 0)
    {
        for (int i = 0; i < scheduleArray.count; i++) {
            NSDictionary *dict = [scheduleArray objectAtIndex:i];
            NSNumber *blockId = [NSNumber numberWithInt:[[dict valueForKey:@"block_id"] intValue]];
            [postsArr addObject:[post fetchPostsForBlockId:blockId]];
        }
        postInfoArray = postsArr;
    }
    else
    {
        
    }
}


#pragma mark - uitableview delegate and datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.segment.selectedSegmentIndex == 1)
        return sectionsArray.count;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.segment.selectedSegmentIndex == 0)
        return scheduleArray.count;
    else
        return [[scheduleArray objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 1)
        return 35.0f;
    
    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.routineTableView.frame) , 45.0f)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.routineTableView.frame) / 2, 5, 100, 25.0f)];

    label.font = [UIFont boldSystemFontOfSize:15.0f];
    label.textAlignment = NSTextAlignmentCenter;
    [label setCenter:CGPointMake(CGRectGetWidth(self.routineTableView.frame) / 2, 20)];
    [view addSubview:label];
    
    if(self.segment.selectedSegmentIndex == 1)
    {
        if(section == 0)
        {
            view.backgroundColor = [UIColor greenColor];
            label.text = @"Active";
            label.textColor = [UIColor blackColor];
        }

        else
        {
            view.backgroundColor = [UIColor redColor];
            label.text = @"Inactive";
            label.textColor = [UIColor whiteColor];
        }
        
        
        return view;
    }
    else
        return nil;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RoutineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *dict;
    NSDictionary *postDict;
    if(self.segment.selectedSegmentIndex == 0)
    {
        dict = (NSDictionary *)[scheduleArray objectAtIndex:indexPath.row];
        
        postDict = (NSDictionary *)[[postInfoArray objectAtIndex:indexPath.row] firstObject];
        
        [cell initCellWithResultSet:dict postDict:postDict];
    }
    else
    {
        dict = (NSDictionary *)[[scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    
    
    self.routineTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    if(indexPath.section == 1)
    {
        if((int)indexPath.row >= lastRow)
            lastRow = (int)indexPath.row;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_chat_routine" sender:indexPath];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if(self.segment.selectedSegmentIndex == 1)
        currentPoint = scrollView.contentOffset;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if(self.segment.selectedSegmentIndex == 1)
    {
        if (scrollView.contentOffset.y < currentPoint.y) {
            self.scrollToTopBtn.hidden = NO;
        }
        else if (scrollView.contentOffset.y > currentPoint.y) {
            self.scrollToTopBtn.hidden = YES;
        }
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(decelerate)
    {
        if(self.routineTableView.contentOffset.y < 0){
            //it means table view is pulled down like refresh
            return;
        }
        else if(self.routineTableView.contentOffset.y >= (self.routineTableView.contentSize.height - self.routineTableView.bounds.size.height)) {
            if(self.segment.selectedSegmentIndex == 1)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    int theLastRow = currentNumberOfRows;
                    currentNumberOfRows += per_page;
                    
                    [self fetchSchedule];
                    
                    int scrollToRow = theLastRow + 2;
                    
                    //
                    NSSet *visibleSections = [NSSet setWithArray:[[self.routineTableView indexPathsForVisibleRows] valueForKey:@"section"]];
                    int visibleSectionsInt = [[[visibleSections allObjects] lastObject] intValue];
                    
                    if(scrollToRow > [[scheduleArray objectAtIndex:visibleSectionsInt] count]) //last row
                    {
                        [self addLoadMoreView:NO];
                        return;
                    }
                    
                    else
                    {
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:visibleSectionsInt];
                        DDLogVerbose(@"scroll to indexpath %ld",(long)newIndexPath.row);
                        [self.routineTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    }
                });
            }
        }
    }
}

- (IBAction)scrollTableToTop:(id)sender
{
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.routineTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    self.scrollToTopBtn.hidden = YES;
}

@end
