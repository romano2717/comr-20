//
//  SurveyListPerPoViewController.h
//  comress
//
//  Created by Diffy Romano on 12/6/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Survey.h"
#import "SurveyTableViewCell.h"
#import "SurveyDetailViewController.h"

@interface SurveyListPerPoViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Survey *survey;
}

@property (nonatomic, weak) IBOutlet UITableView *surveyTable;

@property (nonatomic, strong) NSString *user_id;
@property (nonatomic, strong) NSString *division;
@property (nonatomic, strong) NSArray *surveyArray;


@end
