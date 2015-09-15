//
//  NewIssueViewController.h
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "ImageOptions.h"
#import "ImagePreviewViewController.h"
#import <QuartzCore/QuartzCore.h> 
#import <CoreLocation/CoreLocation.h>
#import "Users.h"
#import "Post.h"
#import "PostImage.h"
#import "ActionSheetStringPicker.h"
#import "Blocks.h"
#import "MPGTextField.h"
#import "Database.h"
#import "Contract_type.h"

@interface NewIssueViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate,UIScrollViewDelegate,MPGTextFieldDelegate>
{
    ImageOptions *imgOpts;
    Users *user;
    Post *post;
    PostImage *postImage;
    Blocks *blocks;
    Database *myDatabase;
    Contract_type *contract_type;
}

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, weak) IBOutlet MPGTextField *postalCodeTextField;
@property (nonatomic, weak) IBOutlet UILabel *postalCodeLabel;
@property (nonatomic, weak) IBOutlet UIButton *postalCodesNearYouButton;
@property (nonatomic, weak) IBOutlet MPGTextField *addressTextField;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *levelTextField;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton *severityBtn;
@property (nonatomic, weak) IBOutlet UIButton *contractTypeBtn;
@property (nonatomic, weak) IBOutlet UIButton *addPhotosButton;
@property (nonatomic, strong) NSNumber *blockId;

@end
