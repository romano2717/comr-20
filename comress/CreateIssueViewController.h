//
//  CreateIssueViewController.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "MPGTextField.h"
#import <CoreLocation/CoreLocation.h>
#import "Blocks.h"
#import "ImagePreviewViewController.h"
#import "ImageOptions.h"
#import "ActionSheetStringPicker.h"
#import "Users.h"
#import "Post.h"
#import "PostImage.h"
#import "SurveyDetailViewController.h"


@interface CreateIssueViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate,UIScrollViewDelegate,MPGTextFieldDelegate>
{
    Database *myDatabase;
    Blocks *blocks;
    ImageOptions *imgOpts;
    Users *user;
    Post *post;
    PostImage *postImage;
    
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
@property (nonatomic, weak) IBOutlet UILabel *contractTypesLabel;
@property (nonatomic, weak) IBOutlet UIButton *addPhotosButton;
@property (nonatomic, strong) NSNumber *blockId;

@property (nonatomic, strong) NSNumber *surveyId;
@property (nonatomic, strong) NSNumber *feedBackId;

@property (nonatomic, strong) NSDictionary *surveyDetail;
@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic) BOOL postalCodeFound;

@property (nonatomic, strong) NSArray *selectedContractTypesArr;
@property (nonatomic, strong) NSString *selectedContractTypesString;

@property (nonatomic) BOOL pushFromSurveyAndModalFromFeedback;

@property (nonatomic) BOOL crmAutoAssignToMeMaintenance;
@property (nonatomic) BOOL crmAutoAssignToMeOthers;

@property (nonatomic, strong) NSString *feedBackDescription;
@end
