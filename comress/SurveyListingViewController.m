//
//  SurveyListingViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyListingViewController.h"
#import "SurveyViewController.h"
#import "SurveyListPerPoViewController.h"

@interface SurveyListingViewController ()

@end

@implementation SurveyListingViewController

@synthesize surveyArray,segment, clientSurveyIdIncompleteSurvey, resumeSurveyAtQuestionIndex;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    reloadSurveyList = NO;
    
    myDatabase = [Database sharedMyDbManager];
    survey = [[Survey alloc] init];
    
    //check what kind of account is logged in
    POisLoggedIn = YES; //CT_NU uses the same logic as PO
    
    
    //PM and CT_SUP have the same function, structure and grouping logic
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PM"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SUP"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"]  || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"GM"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SA"])
    {
        PMisLoggedIn = YES;
        POisLoggedIn = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareSurveyReload) name:@"fetchSurveyNewSurveyNotification" object:nil];
    
    [self fetchSurvey];
}

- (void)prepareSurveyReload
{
    reloadSurveyList = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.hidesBottomBarWhenPushed = NO;
    
    [self adjustTableRowHeightForPM];
    
    if(reloadSurveyList)
    {
        [self fetchSurvey];
        reloadSurveyList = NO;
    }
    
    [self setSegmentTextSizeToFixed];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.surveyTableView reloadData];
    
    [self setSegmentTextSizeToFixed];
}


- (void)setSegmentTextSizeToFixed
{
    //set the uisegment text size to a fixed value
    UIFont *font = [UIFont boldSystemFontOfSize:segmentTextSize];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    [self.segment setTitleTextAttributes:attributes forState:0|1|2];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.segment setNeedsDisplay];
    });
}

- (IBAction)segmentChanged:(id)sender
{
    [self fetchSurvey];
}

- (IBAction)createNewSurvey:(id)sender
{
    resumeSurveyAtQuestionIndex = -2;//new survey
    clientSurveyIdIncompleteSurvey = 0;
    [self performSegueWithIdentifier:@"push_new_survey" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if(POisLoggedIn)
    {
        if([segue.identifier isEqualToString:@"push_survey_detail_from_list"])
        {
            clientSurveyIdIncompleteSurvey = -1;
            resumeSurveyAtQuestionIndex = -2;
            
            NSIndexPath *indexPath = (NSIndexPath *)sender;
            
            int clientSurveyId = 0;
            int surveyId = 0;
            NSString *theSegment = @"me";
            
            if(segment.selectedSegmentIndex == 0)
            {
                clientSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
            }
            else if (segment.selectedSegmentIndex == 1)
            {
                NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
                NSDictionary *dict = [[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row];
                
                clientSurveyId = [[[dict objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                surveyId = [[[dict objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
                theSegment = @"others";
            }
            else
            {
                clientSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
                theSegment = @"overdue";
            }
            
            SurveyDetailViewController *sdvc = [segue destinationViewController];
            sdvc.surveyId = [NSNumber numberWithInt:surveyId];
            sdvc.clientSurveyId = [NSNumber numberWithInt:clientSurveyId];
        }
        else if ([segue.identifier isEqualToString:@"push_new_survey"])
        {
            SurveyViewController *svc = [segue destinationViewController];
            svc.clientSurveyIdIncompleteSurvey = clientSurveyIdIncompleteSurvey;
            svc.resumeSurveyAtQuestionIndex = resumeSurveyAtQuestionIndex;
        }
    }
    else if(PMisLoggedIn)
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        NSString *theSegment = @"me";
        
        if([segue.identifier isEqualToString:@"push_survey_detail_from_list"])
        {
            clientSurveyIdIncompleteSurvey = -1;
            resumeSurveyAtQuestionIndex = -2;
            
            int clientSurveyId = 0;
            int surveyId = 0;
            
            if(segment.selectedSegmentIndex == 0)
            {
                NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
                
                clientSurveyId = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                
                surveyId = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
                theSegment = @"me";
            }

            else if(segment.selectedSegmentIndex == 1)
            {
                clientSurveyId = [[[[surveyArray safeObjectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                surveyId = [[[[surveyArray safeObjectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
                theSegment = @"others";
            }
            else
            {
                NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
                
                clientSurveyId = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
                
                surveyId = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
                
                theSegment = @"overdue";
            }
            
            SurveyDetailViewController *sdvc = [segue destinationViewController];
            sdvc.surveyId = [NSNumber numberWithInt:surveyId];
            sdvc.clientSurveyId = [NSNumber numberWithInt:clientSurveyId];
        }
        else if ([segue.identifier isEqualToString:@"push_new_survey"])
        {
            SurveyViewController *svc = [segue destinationViewController];
            svc.clientSurveyIdIncompleteSurvey = clientSurveyIdIncompleteSurvey;
            svc.resumeSurveyAtQuestionIndex = resumeSurveyAtQuestionIndex;
        }
        else if ([segue.identifier isEqualToString:@"push_survey_per_po"])
        {
            SurveyListPerPoViewController *svPo = [segue destinationViewController];
            
            NSDictionary *dict = [[surveyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            
            svPo.user_id = [dict valueForKey:@"createdBy"];
            svPo.division = [dict valueForKey:@"division"];
        }
    }
    
}

- (void)fetchSurvey
{
    [survey purgeInActiveSurvey];
    
    if(POisLoggedIn)
        surveyArray = [survey fetchSurveyForSegment2:(int)segment.selectedSegmentIndex];
    else if (PMisLoggedIn)
        surveyArray = [survey fetchSurveyForSegmentForPM:(int)segment.selectedSegmentIndex];
    
//    if(segment.selectedSegmentIndex == 2)//set overdue badge if there's any
//    {
//        if(POisLoggedIn)
//        {
//            if(surveyArray.count > 0)
//                [segment setBadgeNumber:surveyArray.count forSegmentAtIndex:2];
//        }
//    }
    
    [self.surveyTableView reloadData];
}

-(void)adjustTableRowHeightForPM
{
    if(PMisLoggedIn && segment.selectedSegmentIndex == 1)
        self.surveyTableView.estimatedRowHeight = 46.0;
    else
        self.surveyTableView.estimatedRowHeight = 130.0;
    
    self.surveyTableView.rowHeight = UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(POisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0)
            return  nil;
        else if (segment.selectedSegmentIndex == 1)
            return [[[surveyArray firstObject] allKeys] objectAtIndex:section];
    }
    else if (PMisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
            return [[[surveyArray firstObject] allKeys] objectAtIndex:section];
        else if(segment.selectedSegmentIndex == 1)
            return [[[surveyArray objectAtIndex:section] firstObject] valueForKey:@"division"];
            
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(POisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0)
            return surveyArray.count;
        else if (segment.selectedSegmentIndex == 1)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:section];
            NSArray *arr = [[surveyArray firstObject] objectForKey:key];
            return arr.count;
        }
        else
            return surveyArray.count;
    }
    else if (PMisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:section];
            NSArray *arr = [[surveyArray firstObject] objectForKey:key];
            return arr.count;
        }
        else if (segment.selectedSegmentIndex == 1)
        {
            return [[surveyArray objectAtIndex:section] count];
        }
        
    }
    
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(POisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0)
            return 1;
        else if (segment.selectedSegmentIndex == 1)
            return [[[surveyArray firstObject] allKeys] count];
        else
            return 1;
    }
    else if (PMisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
            return [[[surveyArray firstObject] allKeys] count];
        else if (segment.selectedSegmentIndex == 1)
            return surveyArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    static NSString *pmCellIdentifier = @"pmCell";
    
    SurveyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict;
    
    if(POisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0)
            dict = [surveyArray objectAtIndex:indexPath.row];
        else if(segment.selectedSegmentIndex == 1)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
            dict = [[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row];
            
        }
        else
            dict = [surveyArray objectAtIndex:indexPath.row];
    }
    else if (PMisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
            dict = [[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row];
        }
        else if (segment.selectedSegmentIndex == 1)
        {
            dict = [[surveyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pmCellIdentifier];
            
            if(cell == nil)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:pmCellIdentifier];
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",[dict valueForKey:@"createdBy"],[[dict valueForKey:@"count"] intValue]];
            
            return cell;
        }
    }

    [cell initCellWithResultSet:dict forSegment:[NSNumber numberWithLong:segment.selectedSegmentIndex]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(POisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
        {
            int theSurveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
            int theStatus = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"status"] intValue];
            clientSurveyIdIncompleteSurvey = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
            if(theSurveyId == 0 && theStatus == 0)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Service Ambassador" message:@"This survey is not yet finished. Do you wish to continue and complete the survey?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Complete this survey", nil];
                alert.tag = 5000;
                
                [alert show];
            }
            else
            {
                [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
            }
        }
        else
            [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
    }
    
    else if (PMisLoggedIn)
    {
        if(segment.selectedSegmentIndex == 0 || segment.selectedSegmentIndex == 2)
        {
            NSString *key = [[[surveyArray firstObject] allKeys] objectAtIndex:indexPath.section];
            
            int theSurveyId = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"survey_id"] intValue];
            
            int theStatus = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"status"] intValue];
            
            clientSurveyIdIncompleteSurvey = [[[[[[surveyArray firstObject] objectForKey:key] objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
            
            if(theSurveyId == 0 && theStatus == 0)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Service Ambassador" message:@"This survey is not yet finished. Do you wish to continue and complete the survey?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Complete this survey", nil];
                alert.tag = 5000;
                
                [alert show];
            }
            else
            {
                [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
            }
        }
        else if (segment.selectedSegmentIndex == 1)
            [self performSegueWithIdentifier:@"push_survey_per_po" sender:indexPath];
    }

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 5000)
    {
        if(buttonIndex == 1)
            [self prepareForSurveyResume];
    }
}

- (void)prepareForSurveyResume
{
    //get the last question answered by this survey
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select max(question_id) as lastQuestionId from su_answers where client_survey_id = ?",[NSNumber numberWithInt:clientSurveyIdIncompleteSurvey]];
        
        int lastQuestionIndex = 0;
        
        while ([rs next]) {
            lastQuestionIndex = [rs intForColumn:@"lastQuestionId"];
        }
        
        //check if this last question id is the last question or not
        FMResultSet *rsQ = [db executeQuery:@"select max(question_id) as currentLastQIndex from su_questions"];
        int currentLastQuestionIndex = 0;
        while ([rsQ next]) {
            currentLastQuestionIndex = [rsQ intForColumn:@"currentLastQIndex"];
        }
        
        if(lastQuestionIndex < currentLastQuestionIndex)
        {
            resumeSurveyAtQuestionIndex = lastQuestionIndex;
        }
        else if (lastQuestionIndex == currentLastQuestionIndex)
        {
            resumeSurveyAtQuestionIndex = -1; //we don't need to ask questions
        }
    }];
    
    [self performSegueWithIdentifier:@"push_new_survey" sender:nil];
}


@end
