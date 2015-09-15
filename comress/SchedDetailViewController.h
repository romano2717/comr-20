//
//  SchedDetailViewController.h
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "NavigationBarTitleWithSubtitleView.h"
#import "ScheduleTableViewCell.h"
#import "ImageOptions.h"
#import "ImageCaptionViewController.h"
#import "VisibleFormViewController.h"
#import "SDWebImageManager.h"
#import "ImageViewerViewController.h"
#import "ActionSheetStringPicker.h"

@interface SchedDetailViewController : VisibleFormViewController
{
    Database *myDatabase;
    ImageOptions *imgOpts;
}
@property (nonatomic, strong) NSDictionary *jobDetailDict;

@end
