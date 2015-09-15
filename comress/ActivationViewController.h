//
//  ActivationViewController.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "LoginViewController.h"
#import "MBProgressHUD.h"

@interface ActivationViewController : UIViewController
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITextField *activationCodeTextField;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@end
