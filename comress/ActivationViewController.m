//
//  ActivationViewController.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ActivationViewController.h"

@interface ActivationViewController ()

@end

@implementation ActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    __block NSString *dbVersion;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select version from db_version"];
        while ([rs next]) {
            dbVersion = [NSString stringWithFormat:@"%d",[rs intForColumn:@"version"]];
        }
    }];
    self.versionLabel.text = [NSString stringWithFormat:@"%@|%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],dbVersion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doActivate:(id)sender
{
    NSString *activateCode = [self.activationCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(activateCode != nil && activateCode.length > 0)
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@",api_activationUrl,activateCode] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            
            if([[dict valueForKey:@"isValid"] intValue] == 1)
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL q;
                    
                    FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
                    if([rs next])
                    {
                        q = [db executeUpdate:@"update client set activation_code = ?, api_url = ?, environment = ?",activateCode,[dict valueForKey:@"url"],[dict valueForKey:@"environment"]];
                        if(!q)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    else
                    {
                        q = [db executeUpdate:@"insert into client(activation_code, api_url, environment) values(?,?,?)",activateCode,[dict valueForKey:@"url"],[dict valueForKey:@"environment"]];
                        if(!q)
                        {
                            *rollback = YES;
                        }
                    }
                    
                    if(q)
                    {
                        FMResultSet *rs = [db executeQuery:@"select * from client"];
                        while ([rs next]) {
                            myDatabase.clientDictionary = [rs resultDictionary];
                            [myDatabase createAfManager];
                        }
                        
                        [self performSegueWithIdentifier:@"push_the_login" sender:self];
                    }
                }];
            }
            else
            {
                [myDatabase alertMessageWithMessage:@"Invalid Activation code. Please try again."];
            }
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription, THIS_FILE,THIS_METHOD);
        }];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_the_login"])
    {
        LoginViewController *login =  [segue destinationViewController];
    }
}


@end
