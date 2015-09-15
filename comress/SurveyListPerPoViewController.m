//
//  SurveyListPerPoViewController.m
//  comress
//
//  Created by Diffy Romano on 12/6/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyListPerPoViewController.h"
#import "NavigationBarTitleWithSubtitleView.h"

@interface SurveyListPerPoViewController ()

@end

@implementation SurveyListPerPoViewController

@synthesize user_id,division,surveyArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:user_id];
    [navigationBarTitleView setDetailText:division];
    
    self.surveyTable.estimatedRowHeight = 87.0;
    self.surveyTable.rowHeight = UITableViewAutomaticDimension;
    
    survey = [[Survey alloc] init];
    
    surveyArray = [survey surveyForPo:user_id];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_survey_detail_from_list"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        
        int clientSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
        int surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
     
        SurveyDetailViewController *sdvc = [segue destinationViewController];
        sdvc.surveyId = [NSNumber numberWithInt:surveyId];
        sdvc.clientSurveyId = [NSNumber numberWithInt:clientSurveyId];
        sdvc.pushFromSurveyListGroupByPo = YES;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return surveyArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    SurveyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict  = [surveyArray objectAtIndex:indexPath.row];
    
    [cell initCellWithResultSet:dict forSegment:[NSNumber numberWithLong:0]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
    
}

@end
