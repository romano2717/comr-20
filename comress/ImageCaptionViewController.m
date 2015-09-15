//
//  ImageCaptionViewController.m
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ImageCaptionViewController.h"

@interface ImageCaptionViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextView *captionTextView;
@property (nonatomic, weak) IBOutlet UIButton *okbtn;
@property (nonatomic, weak) IBOutlet UILabel *imageTypeLabel;
@end

@implementation ImageCaptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    imgOpts = [ImageOptions new];
    
    self.lastVisibleView = _okbtn;
    
    [[_captionTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[_captionTextView layer] setBorderWidth:1];
    [[_captionTextView layer] setCornerRadius:15];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    DDLogVerbose(@"%@",_scheduleDetailDict);
    
    NSString *imageType = @"Before";
    
    if([[_scheduleDetailDict valueForKey:@"imageType"] intValue] == 2)
        imageType = @"After";
    
    _imageView.image = [_scheduleDetailDict objectForKey:@"image"];
    _imageTypeLabel.text = imageType;
}

- (IBAction)savePhoto:(id)sender
{
    UIImage *image = [_scheduleDetailDict objectForKey:@"image"];
    
    NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
    
    //save the image to app documents dir
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
    [jpegImageData writeToFile:filePath atomically:YES];
    
    NSFileManager *fManager = [[NSFileManager alloc] init];
    if([fManager fileExistsAtPath:filePath] == NO)
        return;
    
    //resize the saved image
    [imgOpts resizeImageAtPath:filePath];
    
    //save the image info to local db
    
    //save full image to comress album
    [myDatabase saveImageToComressAlbum:image];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSNumber *scheduleId = [NSNumber numberWithInt:[[[_scheduleDetailDict objectForKey:@"_selectedImageTemplateDict"] valueForKey:@"ScheduleId"] intValue]];
        NSNumber *checklistId = [NSNumber numberWithInt:[[[_scheduleDetailDict objectForKey:@"_selectedImageTemplateDict"] valueForKey:@"CheckListId"] intValue]];
        NSNumber *imageType = [NSNumber numberWithInt:[[_scheduleDetailDict valueForKey:@"imageType"] intValue]];
        NSString *remark = _captionTextView.text;
        
        BOOL ins = [db executeUpdate:@"insert into rt_schedule_image (schedule_id, checklist_id, image_name, image_type, remark) values (?,?,?,?,?)", scheduleId, checklistId, imageFileName, imageType, remark];
        
        if(!ins)
        {
            *rollback = YES;
            return ;
        }
    }];
    
    [self.navigationController popViewControllerAnimated:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieveLocalScheduleDetail" object:nil];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
