//
//  FeedBackInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedBackInfoViewController.h"

@interface FeedBackInfoViewController ()

@end

@implementation FeedBackInfoViewController

@synthesize feedbackId,feedbackDict,clientfeedbackId,dataArray,issueStatus,cmrStatus;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    contract_type = [[Contract_type alloc] init];
    
    feedbackDict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs;
        
        if([feedbackId intValue] > 0)
            rs = [db executeQuery:@"select * from su_feedback where feedback_id = ?",feedbackId];
        else
            rs = [db executeQuery:@"select * from su_feedback where client_feedback_id = ?",clientfeedbackId];
        
        while ([rs next]) {
            [feedbackDict setObject:[rs resultDictionary] forKey:@"feedback"];
            
            NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_address_id"]];
            NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"address_id"]];
            
            //get address
            FMResultSet *rsGetAdd;
            if([clientAddressId intValue] > 0)
                rsGetAdd = [db executeQuery:@"select * from su_address where client_address_id = ?",clientAddressId];
            else
                rsGetAdd = [db executeQuery:@"select * from su_address where address_id = ?",addressId];
            
            while ([rsGetAdd next]) {
                [feedbackDict setObject:[rsGetAdd resultDictionary] forKey:@"address"];
            }
            
            //get feedback_issue
            FMResultSet *rsFi;
            if([feedbackId intValue] > 0)
                rsFi = [db executeQuery:@"select * from su_feedback_issue where feedback_id = ?",feedbackId];
            else
                rsFi = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ?",clientfeedbackId];
            
            NSMutableArray *fIArray = [[NSMutableArray alloc] init];
            NSMutableArray *postArray = [[NSMutableArray alloc] init];
            
            while ([rsFi next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rsFi intForColumn:@"post_id"]];
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsFi intForColumn:@"client_post_id"]];
                
                if([postId intValue] == 0 && [clientPostId intValue] == 0)
                    [fIArray addObject:[rsFi resultDictionary]];
                
                //get post
                FMResultSet *rsGetPost;
                if([postId intValue] > 0)
                    rsGetPost = [db executeQuery:@"select * from post p, contract_type c where p.post_id = ? and p.contract_type = c.id",postId];
                else
                    rsGetPost = [db executeQuery:@"select * from post p, contract_type c where p.client_post_id = ? and p.contract_type = c.id",clientPostId];
                
                while ([rsGetPost next]) {
                    [postArray addObject:[rsGetPost resultDictionary]];
                }
            }
            
            [feedbackDict setObject:postArray forKey:@"post"];
            [feedbackDict setObject:fIArray forKey:@"feedback_issue"];
        }
    }];
    issueStatus = [NSArray arrayWithObjects:@"Pending",@"Start",@"Stop",@"Completed",@"Close", nil];
    cmrStatus = [NSArray arrayWithObjects:@"Pending",@"Complete",@"Close", nil];
    
    NSDictionary *feedback = [feedbackDict objectForKey:@"feedback"];
    NSDictionary *address = [feedbackDict objectForKey:@"address"];
    NSArray *feedback_issue_array = [feedbackDict objectForKey:@"feedback_issue"];
    NSArray *post_array = [feedbackDict objectForKey:@"post"];
    
    self.locationLabel.text = [address valueForKey:@"address"];
    self.feedBackLabel.text = [feedback valueForKey:@"description"];
    
    NSString *titleStr = @"Feedback";
    
    if([address valueForKey:@"address"] != [NSNull null] && [address valueForKey:@"address"] != nil)
        titleStr = [address valueForKey:@"address"];
    
    self.title = titleStr;
    
    
    //prepare data for the table
    dataArray = [[NSMutableArray alloc] init];
    
    [dataArray addObject:feedback_issue_array];
    [dataArray addObject:post_array];
    
    //remove feedback_issue with post since we already have post dict
//    DDLogVerbose(@"first object %@",[dataArray firstObject]);
//    for (int i = 0; i < [[dataArray firstObject] count]; i++) {
//        NSDictionary *dict = [[dataArray firstObject] objectAtIndex:i];
//        DDLogVerbose(@"%@",dict);
//        if([[dict valueForKey:@"client_post_id"] intValue] > 0 || [[dict valueForKey:@"post_id"] intValue] > 0)
//        {
//            [[dataArray firstObject] removeObject:dict];
//        }
//    }
    
    DDLogVerbose(@"%@",dataArray);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[dataArray objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return dataArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        NSString *crmCount = [NSString stringWithFormat:@"Crm(%lu)",(unsigned long)[[dataArray firstObject] count]];
        return crmCount;
    }
    else
    {
        NSString *issueCount = [NSString stringWithFormat:@"Issues(%lu)",(unsigned long)[[dataArray lastObject] count]];
        return issueCount;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    

    if(indexPath.section == 0)
    {
        NSDictionary *dict = [[dataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        NSString *issue_des;
        
        if([dict valueForKey:@"issue_des"] != [NSNull null] && [dict valueForKey:@"issue_des"] != nil);
            issue_des = [dict valueForKey:@"issue_des"];
        
        cell.textLabel.text = issue_des;
        
        int crmStatusInt = [[dict valueForKey:@"status"] intValue];
        
        NSString *crmStatusStr;
        
        switch (crmStatusInt) {
            case 1:
                crmStatusStr = @"Start";
                break;
            case 4:
                crmStatusStr = @"Close";
                
            default:
                crmStatusStr = @"Pending";
                break;
        }
        
        cell.detailTextLabel.text = crmStatusStr;
    }
    else
    {
        NSDictionary *dict = [[dataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)",[dict valueForKey:@"post_topic"],[dict valueForKey:@"contract"]] ;
        cell.detailTextLabel.text = [issueStatus objectAtIndex:[[dict valueForKey:@"status"] intValue]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.cameFromChat == NO)
    {
        if(indexPath.section == 1)
        {
            NSDictionary *dict = [[dataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            
            [self performSegueWithIdentifier:@"push_chat_issues" sender:dict];
        }
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_chat_issues"])
    {
        NSDictionary *dict = sender;
        
        
        if([dict valueForKey:@"post_id"] != [NSNull null])
        {
            IssuesChatViewController *issuesVc = [segue destinationViewController];
            issuesVc.postId = [[dict valueForKey:@"client_post_id"] intValue];
            issuesVc.isFiltered = YES;
            issuesVc.ServerPostId = [[dict valueForKey:@"post_id"] intValue];
            issuesVc.cameFromSurvey = YES;
        }
        else
        {
            IssuesChatViewController *issuesVc = [segue destinationViewController];
            issuesVc.postId = [[dict valueForKey:@"client_post_id"] intValue];
            issuesVc.isFiltered = YES;
            issuesVc.ServerPostId = 0;
            issuesVc.cameFromSurvey = YES;
        }
    }
    
}


@end
