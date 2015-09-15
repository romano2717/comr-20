//
//  SurveyDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyDetailViewController.h"

@interface SurveyDetailViewController ()

@end

@implementation SurveyDetailViewController

@synthesize clientSurveyId,surveyId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    survey = [[Survey alloc] init];
    
    __block float averageRating = 0.0f;
    
    //get average rating of this survey
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select average_rating from su_survey where client_survey_id = ? or survey_id = ?",clientSurveyId,surveyId];

        while ([rs next]) {
            averageRating = [rs doubleForColumn:@"average_rating"];
        }
    }];
    
    self.percentageRating.text = [NSString stringWithFormat:@"%.2f%%",averageRating];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self fetchSurveyDetail];
}

- (IBAction)popResidentInfForThisSurvey:(id)sender
{
    NSNumber *theSurveyId = [NSNumber numberWithInt:0];
    
    if([surveyId intValue] > 0)
        theSurveyId = surveyId;
    else
        theSurveyId = clientSurveyId;
    
    [self performSegueWithIdentifier:@"modal_resident_info_edit" sender:theSurveyId];
}

-(void) viewWillDisappear:(BOOL)animated
{
    if(self.pushFromSurveyListGroupByPo == NO && self.pushFromChat == NO)
    {
        if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
        {
            [self backButtonPressed];
            [self.navigationController popViewControllerAnimated:NO];
            
        }
        [super viewWillDisappear:animated];
    }
}

-(void)backButtonPressed
{ 
    if(self.pushFromResidentInfo)
    {
        //pop to tab
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    if(self.pushFromIssue)
    {
        //pop to tab
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleSegment:(id)sender
{
    [self fetchSurveyDetail];
}

- (void)fetchSurveyDetail
{
    self.dataArray = [survey surveyDetailForSegment:self.segment.selectedSegmentIndex forSurveyId:surveyId forClientSurveyId:clientSurveyId];
    
    [self.surveyDetailTableView reloadData];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_add_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.currentClientSurveyId = surveyId;
        fvc.pushFromSurveyDetail = YES;
    }
    else if ([segue.identifier isEqualToString:@"modal_resident_info_edit"])
    {
        ResidentPopInfoViewController *rpvc = [segue destinationViewController];
        rpvc.surveyId = surveyId;
        rpvc.clientSurveyId = clientSurveyId;
    }
    else if([segue.identifier isEqualToString:@"push_feedback_info"])
    {
        NSDictionary *dict = (NSDictionary *)sender;
        FeedBackInfoViewController *fivc = [segue destinationViewController];
        
        NSNumber *clientFeedBackId = [NSNumber numberWithInt:[[[dict objectForKey:@"feedback"] valueForKey:@"client_feedback_id"] intValue]];
        NSNumber *feedBackId = [NSNumber numberWithInt:[[[dict objectForKey:@"feedback"] valueForKey:@"feedback_id"] intValue]];
        
        fivc.feedbackId = feedBackId;
        fivc.clientfeedbackId = clientFeedBackId;
        if(self.pushFromChat)
            fivc.cameFromChat = YES;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.segment.selectedSegmentIndex == 0)
    {
        static NSString *questionCell = @"quetionsCell";
        QuestionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:questionCell forIndexPath:indexPath];
        
        NSDictionary *dict = [self.dataArray objectAtIndex:indexPath.row];
        
        [cell initCellWithResultSet:dict];
        return cell;
    }
    
    else
    {
        static NSString *feedBackCell = @"feedbackCell";
        FeedbackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:feedBackCell forIndexPath:indexPath];
        NSDictionary *dict = [self.dataArray objectAtIndex:indexPath.row];
        
        [cell initCellWithResultSet:dict];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.segment.selectedSegmentIndex == 1) {
        NSDictionary *dict = [self.dataArray objectAtIndex:indexPath.row];
        
        [self performSegueWithIdentifier:@"push_feedback_info" sender:dict];
    }
}

- (IBAction)addFeedBack:(id)sender
{
    [self performSegueWithIdentifier:@"push_add_feedback" sender:self];
}


@end
