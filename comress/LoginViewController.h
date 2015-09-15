//
//  LoginViewController.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApiCallUrl.h"
#import "Database.h"
#import "MBProgressHUD.h"

@interface LoginViewController : UIViewController<UITextFieldDelegate>
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITextField *companyIdTextField;
@property (nonatomic, weak) IBOutlet UITextField *userIdTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@end
