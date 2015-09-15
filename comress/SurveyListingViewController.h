//
//  SurveyListingViewController.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "Survey.h"
#import "SurveyTableViewCell.h"
#import "SurveyDetailViewController.h"
#import "MESegmentedControl.h"

@interface SurveyListingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate, UIAlertViewDelegate>
{
    Database *myDatabase;
    Survey *survey;
    
    BOOL PMisLoggedIn;
    BOOL POisLoggedIn;
    
    BOOL reloadSurveyList;
}
@property (nonatomic, weak) IBOutlet UITableView *surveyTableView;
@property (nonatomic, weak) IBOutlet MESegmentedControl *segment;

@property (nonatomic, strong) NSArray *surveyArray;

@property (nonatomic) int clientSurveyIdIncompleteSurvey;
@property (nonatomic) int resumeSurveyAtQuestionIndex;


@end
