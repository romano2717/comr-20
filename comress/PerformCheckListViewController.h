//
//  PerformCheckListViewController.h
//  comress
//
//  Created by Diffy Romano on 16/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListCustomCell.h"
#import "Database.h"
#import "RoutineSynchronize.h"

@interface PerformCheckListViewController : UIViewController
{
    Database *myDatabase;
    RoutineSynchronize *routineSync;
}
@property (nonatomic, strong) NSDictionary *scheduleDict;

@end
