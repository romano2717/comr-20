//
//  JobListViewController.h
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "JobListTableViewCell.h"
#import "MBProgressHUD.h"
#import "SchedDetailViewController.h"

@interface JobListViewController : UIViewController
{
    Database *myDatabase;
}

@property (nonatomic, strong)NSDictionary *scheduleDetailDict;

@end
