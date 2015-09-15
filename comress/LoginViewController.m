//
//  LoginViewController.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "LoginViewController.h"
#import "Synchronize.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    myDatabase = [Database sharedMyDbManager];
    
    __block NSString *dbVersion;
    __block NSString *env;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select version from db_version"];
        while ([rs next]) {
            dbVersion = [NSString stringWithFormat:@"%d",[rs intForColumn:@"version"]];
        }
        
        FMResultSet *rs2 = [db executeQuery:@"select environment from client"];
        while ([rs2 next]) {
            env = [rs2 stringForColumn:@"environment"];
        }
    }];

    if([[env lowercaseString] isEqualToString:@"live"])
    {
        self.versionLabel.text = [NSString stringWithFormat:@"%@|%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],dbVersion];
    }
    else
    {
        self.versionLabel.text = [NSString stringWithFormat:@"%@|%@|%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],dbVersion,env];
    }
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.companyIdTextField.text = @"";
    self.userIdTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.2);
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [self doLogin:self];
    
    return YES;
}

- (IBAction)doLogin:(id)sender
{
    NSString *companyId = [self.companyIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *userId = [self.userIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(companyId != nil && userId != nil && password != nil && companyId.length > 0 && userId.length > 0 && password.length > 0)
    {
        //the sync might still be running, and some data might still be inserted, clear it first
        Synchronize *sync = [Synchronize sharedManager];
        sync.stop = YES;
        
        [self resetTables];
        
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

            //get user device token
            FMResultSet *rsToken = [db executeQuery:@"select device_token from device_token"];
            NSString *deviceToken;
            
            if(![rsToken next])
            {
                [myDatabase alertMessageWithMessage:@"No Device token found! Please make sure the Notification is enabled for Comress"];
                return;
            }
            else
            {
                deviceToken = [rsToken stringForColumn:@"device_token"];
            }
            
            //get app version
            NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
            
            NSNumber *deviceId = [myDatabase.userDictionary valueForKey:@"device_id"] ? [myDatabase.userDictionary valueForKey:@"device_id"] : [NSNumber numberWithInt:0];
            
            NSDictionary *params = @{ @"loginUser" : @{@"UserId" : userId, @"CompanyId" : companyId, @"Password" : password, @"DeviceToken" : deviceToken, @"AppVersion" : appVersion, @"OsType" : @"2"},@"DeviceId":deviceId};
            
            
            __block BOOL user_q = NO;
            __block BOOL client_q = NO;
            __block BOOL loginOk = YES;
            
            [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_login] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSDictionary *dict = (NSDictionary *) responseObject;

                if([dict objectForKey:@"ActiveUser"] != [NSNull null])
                {
                    NSDictionary *ActiveUser = [dict objectForKey:@"ActiveUser"];
                    
                    NSString *res_CompanyId = [ActiveUser valueForKey:@"CompanyId"];
                    NSString *res_UserId = [ActiveUser valueForKey:@"UserId"];
                    NSString *res_CompanyName = [ActiveUser valueForKey:@"CompanyName"];
                    NSNumber *res_GroupId =  [NSNumber numberWithInt:[[ActiveUser valueForKey:@"GroupId"] intValue]];
                    NSString *res_GroupName = [ActiveUser valueForKey:@"GroupName"];
                    NSString *res_UserName = [ActiveUser valueForKey:@"UserName"];
                    NSString *res_SessionId = [ActiveUser valueForKey:@"SessionId"];
                    NSNumber *res_deviceId = [NSNumber numberWithInt:[[ActiveUser valueForKey:@"DeviceId"] intValue]];
                    NSNumber *is_active = [NSNumber numberWithInt:1];
                    NSNumber *contract_type = [NSNumber numberWithInt:[[ActiveUser valueForKey:@"ConTypeId"] intValue]];
                    
                    //update/insert user
                    FMResultSet *rsUser = [db executeQuery:@"select user_id from users where user_id = ?",res_UserId];
                    if([rsUser next])
                    {
                        //returning user
                        user_q = [db executeUpdate:@"update users set company_id = ?, user_id = ?, company_name = ?, group_id = ?, group_name = ?, full_name = ?, guid = ?, device_id = ?, is_active = ?, contract_type = ? where user_id = ?",res_CompanyId, res_UserId, res_CompanyName, res_GroupId, res_GroupName, res_UserName, res_SessionId, res_deviceId, is_active, contract_type, res_UserId];
                        
                        if(!user_q)
                        {
                            *rollback = YES;
                            return ;
                        }
                    }
                    else
                    {
                        //new user.
                        myDatabase.userBlocksInitComplete = 0;
                        myDatabase.userBlocksMappingInitComplete = NO;
                        
                        user_q = [db executeUpdate:@"insert into users (company_id, user_id, company_name, group_id, group_name, full_name, guid, device_id, is_active,contract_type) values (?,?,?,?,?,?,?,?,?,?)",res_CompanyId,res_UserId,res_CompanyName,res_GroupId,res_GroupName,res_UserName,res_SessionId,res_deviceId,is_active,contract_type];
                        if(!user_q)
                        {
                            *rollback = YES;
                            loginOk = NO;
                            [myDatabase alertMessageWithMessage:@"Login failed. try again."];
                            return;
                        }
                        //make this user download his data by resetting some tables in issues
                        NSArray *tablesTodelete = @[@"blocks_user",@"blocks_user_last_request_date",@"comment",@"comment_noti",@"post",@"post_image",@"blocks_user",@"blocks_user_last_request_date",@"comment_last_request_date",@"comment_noti_last_request_date",@"post_image_last_request_date",@"post_last_request_date"];
                        
                        for (int i = 0; i < tablesTodelete.count; i++) {
                            NSString *delTbString = [NSString stringWithFormat:@"delete from %@",[tablesTodelete objectAtIndex:i]];
                            BOOL delTb = [db executeUpdate:delTbString];
                            
                            if(!delTb)
                            {
                                *rollback = YES;
                                return;
                            }
                        }
                        
                        //delete images? image last request date is reset to default
                        NSArray *directoryContents =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] error:NULL];
                        
                        if([directoryContents count] > 0)
                        {
                            for (NSString *path in directoryContents)
                            {
                                NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:path];
                                
                                NSRange r =[fullPath rangeOfString:@".jpg"];
                                if (r.location != NSNotFound || r.length == [@".jpg" length])
                                {
                                    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                                }
                            }
                        }
                    }
                    
                    //insert/update client user_guid
                    client_q = [db executeUpdate:@"update client set user_guid = ?",res_SessionId];
                    
                    if(!client_q)
                    {
                        loginOk = NO;
                        *rollback = YES;
                        [myDatabase alertMessageWithMessage:@"Login failed. try again."];
                        return;
                    }
                    else
                    {
                        FMResultSet *rs = [db executeQuery:@"select * from client"];
                        while ([rs next]) {
                            myDatabase.clientDictionary = [rs resultDictionary];
                        }
                    }
                    
                    //this will recreate afmanager,user with session id as header;
                    [myDatabase createClient];
                    [myDatabase createUser];
                    [myDatabase createAfManager];
                    
                    NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@&deviceToken=%@",res_deviceId,[myDatabase.deviceTokenDictionary valueForKey:@"device_token"]];
                    
                    //update device token
                    [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@%@",myDatabase.api_url,api_update_device_token,urlParams] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        
                        DDLogVerbose(@"update device token %@",responseObject);
                        
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
                    }];
                    
                    
                    //send app version
                    if([res_deviceId intValue] != 0)
                    {
                        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
                        NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@&appVersion=%@",res_deviceId,appVersion];

                        [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@%@",myDatabase.api_url,api_send_app_version,urlParams] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                            DDLogVerbose(@"update app version %@",responseObject);
                            
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
                        }];
                    }
                    
                    
                    if(loginOk)
                    {
                        [Answers logCustomEventWithName:@"login" customAttributes:myDatabase.userDictionary];
                        
                        [sync downloadUserSettings];
                        [self performSegueWithIdentifier:@"push_main_view" sender:self];
                    }
                    else
                        DDLogVerbose(@"%@ [%@-%@]",[db lastErrorMessage],THIS_FILE,THIS_METHOD);
                }
                else
                {
                    [myDatabase alertMessageWithMessage:@"Invalid login. Please try again."];
                }
                
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:[NSString stringWithFormat:@"%@",error] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                [alert show];
                
                
                DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
                
            }];
        }];
    }
}

- (void)resetTables
{
    NSArray *tableToDelete =
    @[@"blocks_last_request_date",
      @"blocks_user",
      @"blocks_user_last_request_date",
      @"comment_last_request_date",
      @"comment_noti_last_request_date",
      @"post_last_request_date",
      @"post_image_last_request_date",
      @"ro_checkarea_last_req_date",
      @"ro_checklist_last_req_date",
      @"ro_job_last_req_date",
      @"ro_scanchecklist_last_req_date",
      @"ro_scanchecklist_blk_last_req_date",
      @"ro_schedule_last_req_date",
      @"ro_user_blk_last_req_date",
      @"su_feedback_issues_last_req_date",
      @"su_questions_last_req_date",
      @"su_survey_last_req_date"];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        for (int i = 0; i < tableToDelete.count; i++) {
            NSString *tbl = [NSString stringWithFormat:@"delete from %@",[tableToDelete objectAtIndex:i]];
            BOOL del = [db executeUpdate:tbl];
            
            if(!del)
            {
                *rollback = YES;
                return ;
            }
        }
        
    }];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"login segue %@",segue.identifier);
    if([segue.identifier isEqualToString:@"push_main_view"])
    {
        [[self navigationController] setNavigationBarHidden:YES];
        [segue destinationViewController];
    }
    
}


@end
