//
//  JobListViewController.m
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "JobListViewController.h"

@interface JobListViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *jobListTableView;
@property (nonatomic, strong) NSArray *jobList;
@property (nonatomic, strong) NSDictionary *SchedulesContainer;
@end

@implementation JobListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self getJobList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadJobListTable
{
    [_jobListTableView reloadData];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    self.title = [_SchedulesContainer valueForKey:@"BlockName"];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_schedule_detail"])
    {
        NSIndexPath *indexPath = sender;
        
        SchedDetailViewController *skedDetail = [segue destinationViewController];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[_jobList objectAtIndex:indexPath.row]];
        [dict setObject:[_scheduleDetailDict valueForKey:@"blockDesc"] forKey:@"blockDesc"];
        
        skedDetail.jobDetailDict = dict;
    }
}


- (void)getJobList
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSNumber *blockId = [NSNumber numberWithInt:[[_scheduleDetailDict valueForKey:@"blk_id"] intValue]];
    NSDate *scheduleDate = [NSDate dateWithTimeIntervalSince1970:[[_scheduleDetailDict valueForKey:@"ScheduledDate"] doubleValue]];
    NSString *scheduleDateString = [myDatabase createWcfDateWithNsDate:scheduleDate];
    
    NSDictionary *params = @{@"blkId":blockId,@"scheduleDate":scheduleDateString};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_get_job_list_for_block] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        _SchedulesContainer = [responseObject objectForKey:@"SchedulesContainer"];
        
        _jobList = [_SchedulesContainer objectForKey:@"ScheduleList"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadJobListTable];
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _jobList.count;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     static NSString *cellIdentifier = @"cell";
     
     JobListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
     
     NSDictionary *dict = [_jobList objectAtIndex:indexPath.row];
     
     [cell initCellWithResultSet:dict];
 
     return cell;
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_schedule_detail" sender:indexPath];
}

@end
