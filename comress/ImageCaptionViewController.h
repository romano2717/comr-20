//
//  ImageCaptionViewController.h
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "VisibleFormViewController.h"
#import "ImageOptions.h"

@interface ImageCaptionViewController : VisibleFormViewController
{
    Database *myDatabase;
    ImageOptions *imgOpts;
}
@property (nonatomic, strong) NSDictionary *scheduleDetailDict;
@end
