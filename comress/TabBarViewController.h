//
//  TabBarViewController.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "Device_token.h"
#import "Users.h"
#import "Blocks.h"
#import "Synchronize.h"

@interface TabBarViewController : UITabBarController<UITabBarControllerDelegate>
{
    Database *myDatabase;
    Users *user;
    Blocks *blocks;
    Synchronize *sync;
}

@property (nonatomic, strong) NSString *segueTo;
@end
