//
//  ImageViewerViewController.h
//  comress
//
//  Created by Diffy Romano on 10/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "NavigationBarTitleWithSubtitleView.h"

@interface ImageViewerViewController : UIViewController
{
    Database *myDatabase;
}

@property (nonatomic, strong) NSDictionary *imageTemplateDict;

@end
