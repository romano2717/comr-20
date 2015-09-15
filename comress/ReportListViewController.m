//
//  ReportListViewController.m
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportListViewController.h"
#import "ReportDetailViewController.h"

@interface ReportListViewController ()

@end

@implementation ReportListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PM"] == YES || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"GM"] == YES || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SA"] == YES)
        PMisLoggedIn = YES;
    else if ([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"] == YES)
        POisLoggedIn = YES;
    
    self.headersArray = [NSArray arrayWithObjects:@"Service Ambassador", nil];
        
    //default by PO
    self.reportsArray = [NSArray arrayWithObjects:[NSArray arrayWithObjects:@"Survey",@"Feedback Issues",@"Average Sentiment", nil], nil];

    
    if(PMisLoggedIn)
        self.reportsArray = [NSArray arrayWithObjects:[NSArray arrayWithObjects:@"Survey",@"Feedback Issues",@"Average Sentiment", nil], nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_report_detail"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        
        ReportDetailViewController *rdvc = [segue destinationViewController];
        rdvc.reportType = [[self.reportsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        rdvc.PMisLoggedIn = PMisLoggedIn;
        rdvc.POisLoggedIn = POisLoggedIn;
    }
}

#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.headersArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.reportsArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{

    return [self.headersArray objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    
    cell.textLabel.text = [[self.reportsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_report_detail" sender:indexPath];

}

@end
