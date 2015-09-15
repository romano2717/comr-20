//
//  GenericWebviewViewController.h
//  comress
//
//  Created by Diffy Romano on 28/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApiCallUrl.h"
#import "Database.h"

@interface GenericWebviewViewController : UIViewController
{
    Database *myDatabase;
}
@property (nonatomic, weak) IBOutlet UIWebView *theWebView;

@end
