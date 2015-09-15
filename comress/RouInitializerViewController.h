//
//  RouInitializerViewController.h
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Check_list.h"
#import "Check_area.h"
#import "Scan_Check_list.h"
#import "Scan_Check_List_Block.h"
#import "Job.h"
#import "Schedule.h"

@interface RouInitializerViewController : UIViewController
{
    Database *myDatabase;
    
    Check_list *check_list;
    Check_area *check_area;
    Scan_Check_list *scan_check_list;
    Scan_Check_List_Block *scan_check_list_block;
    Job *job;
    Schedule *schedule;
}

@property (nonatomic, weak) IBOutlet UILabel *processLabel;
@end
