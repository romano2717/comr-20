//
//  TabBarViewController.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "TabBarViewController.h"
#import "ActivationViewController.h"
#import "RoutineNavigationViewController.h"

@interface TabBarViewController ()
{
    BOOL needToActivate;
    BOOL needToLogin;
}
@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    NSMutableArray *tabbarViewControllers = [NSMutableArray arrayWithArray: [self viewControllers]];
    
    
    //manually add routine vc to tabbar
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"RoutineStoryboard" bundle:[NSBundle mainBundle]];

    UITabBarItem *routineTabItem = [[UITabBarItem alloc] initWithTitle:@"Routine" image:[UIImage imageNamed:@"Routine_05@2x"] tag:1];
    RoutineNavigationViewController *routineNav = [storyboard instantiateViewControllerWithIdentifier:@"RoutineNavigationViewController"];
    [routineNav setTabBarItem:routineTabItem];
    [tabbarViewControllers insertObject:routineNav atIndex:1];

    //tabs: issue, routine, sv amb, statistics, settings
    
    //hide svc. ambass, and statistics for contractor, contractor_sa and contractor sup
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_NU"] == YES || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"] == YES || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SUP"] == YES)
    {
        [tabbarViewControllers removeObjectAtIndex: 2]; // svc amabassador
        [tabbarViewControllers removeObjectAtIndex: 2]; // statistics
    }
    
    //only show the svc. ambassador
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PR"])
    {
        [tabbarViewControllers removeObjectAtIndex:0]; //issue
        [tabbarViewControllers removeObjectAtIndex:0]; //statistics
    }
    
    [self setViewControllers: tabbarViewControllers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    needToActivate = NO;
    needToLogin = NO;
    
    //check for a valid activation code
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *activationCode = nil;
        
        FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
        while([rs next])
        {
            activationCode = [rs stringForColumn:@"activation_code"];
        }
        
        if(activationCode == nil || activationCode.length == 0)
        {
            needToActivate = YES;
        }
        else
        {
            //check for active login
            FMResultSet *rsClient = [db executeQuery:@"select c.user_guid, u.* from client c, users u where c.user_guid = u.guid and u.is_active = ?",[NSNumber numberWithInt:1]];
            
            if(![rsClient next])
            {
                needToLogin = YES;
            }
        }
    }];
    
    if(needToActivate)
    {
        self.segueTo = @"modal_activation";
    }
    else if (needToLogin)
    {
        self.segueTo = @"modal_login";
    }
    else
    {
        
        __block BOOL needtoInit = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select initialise from client where initialise = ?",[NSNumber numberWithInt:0]];
            if([rs next] == YES)
                needtoInit = YES;
            else
            {
                self.segueTo = nil; //no need to segue
                myDatabase.initializingComplete = 1;
                myDatabase.userBlocksInitComplete = 1;
                myDatabase.userBlocksMappingInitComplete = 1;
            }
        }];
        if(needtoInit == YES)
            self.segueTo = @"modal_initializer";
        else
        {
            //start sync
            sync = [Synchronize sharedManager];
            sync.stop = NO;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(self.segueTo != nil)
        [self performSegueWithIdentifier:self.segueTo sender:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"modal_activation"])
    {
        [segue destinationViewController];
    }
    
    if([segue.identifier isEqualToString:@"modal_login"])
    {
        [segue destinationViewController];
    }
}


@end
