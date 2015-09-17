//
//  ImageViewerViewController.m
//  comress
//
//  Created by Diffy Romano on 10/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ImageViewerViewController.h"
#import "ResponsiveLabel.h"

static NSString *kExpansionToken = @"...Read More";
static NSString *kCollapseToken = @" Read Less";

@interface ImageViewerViewController ()
@property (nonatomic, weak) IBOutlet UILabel *imageTypelabel;
@property (nonatomic, weak) IBOutlet ResponsiveLabel *remarksLabel;
@property (nonatomic, weak) IBOutlet UILabel *imageCounterLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic, strong) NSMutableArray *imagesArray;
@property (nonatomic) int currentImageIndexCounter;
@property (nonatomic) int currentImageIndex;
@property (nonatomic, strong) NSString *imageTypeString;
@end

@implementation ImageViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    _imagesArray = [[NSMutableArray alloc] init];
    
    _currentImageIndexCounter = 1;
    
    NSDictionary *imageTemplate = [_imageTemplateDict objectForKey:@"imageTemplate"];
    
    NSNumber *CheckListId = [NSNumber numberWithInt:[[imageTemplate valueForKey:@"CheckListId"] intValue]];
    NSNumber *ScheduleId = [NSNumber numberWithInt:[[imageTemplate valueForKey:@"ScheduleId"] intValue]];
    
    int imageType = [[_imageTemplateDict valueForKey:@"imageType"] intValue];
    
    _imageTypeString = @"";
    
    if(imageType == 2)
        _imageTypeString = @"After";
    else if (imageType == 1)
        _imageTypeString = @"Before";
    
    
    //get all the images for this checklist
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from rt_schedule_image where checklist_id = ? and schedule_id = ? and image_type = ? order by client_schedule_image_id desc",CheckListId,ScheduleId,[NSNumber numberWithInt:imageType]];
        if(imageType == 0) //all images
            rs = [db executeQuery:@"select * from rt_schedule_image where checklist_id = ? and schedule_id = ? order by client_schedule_image_id asc",CheckListId,ScheduleId];
        
        while ([rs next]) {
            NSString *imageName = [rs stringForColumn:@"image_name"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            
            int theImageType = [rs intForColumn:@"image_type"];
            NSString *theImageTypeString = @"Before";
            
            if(theImageType == 2)
                theImageTypeString = @"After";
            
            [_imagesArray addObject:@{@"image":image,@"remarks":[rs stringForColumn:@"remark"],@"imageType":theImageTypeString}];
            
        }
    }];
    
    if(_imagesArray.count == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"COMRESS" message:@"There are no images added for this checklist yet. Add photos by tapping the 'Before' or 'After' label." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        
        [alert show];
        
        [self.navigationController popViewControllerAnimated:YES];
        
        return;
    }
    
    _imageTypelabel.text = _imageTypeString;
    _imageCounterLabel.text = [NSString stringWithFormat:@"%d/%d image",_currentImageIndexCounter,(int)_imagesArray.count];
    
    _imageView.image = [[_imagesArray firstObject] objectForKey:@"image"];
    _remarksLabel.text = [[_imagesArray firstObject] objectForKey:@"remarks"];
    _imageTypelabel.text = [[_imagesArray firstObject] objectForKey:@"imageType"];
    
    
    NSMutableAttributedString *attribString = [[NSMutableAttributedString alloc]initWithString:kExpansionToken];
    [attribString addAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:_remarksLabel.font}
                          range:NSMakeRange(3, kExpansionToken.length - 3)];
    [_remarksLabel setAttributedTruncationToken:attribString withAction:^(NSString *tappedString) {
        [self expandRemarksText];
    }];
    
    [self configureText:[[_imagesArray firstObject] objectForKey:@"remarks"] forExpandedState:NO];
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
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:[[_imageTemplateDict objectForKey:@"jobDesc"] valueForKey:@"blockDesc"]];
    [navigationBarTitleView setDetailText:[[_imageTemplateDict objectForKey:@"imageTemplate"] valueForKey:@"Title"]];
}

- (IBAction)nextImage:(id)sender
{
    if(_currentImageIndex < _imagesArray.count - 1)
    {
        _currentImageIndex++;
        _currentImageIndexCounter++;
        
        if(_currentImageIndex > _imagesArray.count)
        {
            _currentImageIndex = (int)_imagesArray.count + 1;
            _currentImageIndexCounter = 1;
        }
        
        _imageView.image = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"image"];
        _remarksLabel.text = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"];
        _imageCounterLabel.text = [NSString stringWithFormat:@"%d/%d image",_currentImageIndexCounter,(int)_imagesArray.count];
        _imageTypelabel.text = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"imageType"];
        
        NSMutableAttributedString *attribString = [[NSMutableAttributedString alloc]initWithString:kExpansionToken];
        [attribString addAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:_remarksLabel.font}
                              range:NSMakeRange(3, kExpansionToken.length - 3)];
        [_remarksLabel setAttributedTruncationToken:attribString withAction:^(NSString *tappedString) {
            [self expandRemarksText];
        }];
        
        [self configureText:[[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"] forExpandedState:NO];
    }
}

- (IBAction)previousImage:(id)sender
{
    if(_currentImageIndex >= 0)
    {
        _currentImageIndex--;
        _currentImageIndexCounter--;
        
        if(_currentImageIndex < 0)
        {
            _currentImageIndex = 0;
            _currentImageIndexCounter = 1;
        }
        
        _imageView.image = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"image"];
        _remarksLabel.text = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"];
        _imageCounterLabel.text = [NSString stringWithFormat:@"%d/%d image",_currentImageIndexCounter,(int)_imagesArray.count];
        _imageTypelabel.text = [[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"imageType"];
        
        NSMutableAttributedString *attribString = [[NSMutableAttributedString alloc]initWithString:kExpansionToken];
        [attribString addAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:_remarksLabel.font}
                              range:NSMakeRange(3, kExpansionToken.length - 3)];
        [_remarksLabel setAttributedTruncationToken:attribString withAction:^(NSString *tappedString) {
            [self expandRemarksText];
        }];
        
        [self configureText:[[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"] forExpandedState:NO];
    }
}

- (void)configureText:(NSString*)str forExpandedState:(BOOL)isExpanded {
    NSMutableAttributedString *finalString;
    if (isExpanded) {
        NSString *expandedString = [NSString stringWithFormat:@"%@%@",str,kCollapseToken];
        finalString = [[NSMutableAttributedString alloc]initWithString:expandedString attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        
        PatternTapResponder tap = ^(NSString *string) {
            [self collapseRemarksText];
        };
        [finalString addAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],RLTapResponderAttributeName:tap}
                             range:[expandedString rangeOfString:kCollapseToken]];
        [finalString addAttributes:@{NSFontAttributeName:_remarksLabel.font} range:NSMakeRange(0, finalString.length)];
        _remarksLabel.numberOfLines = 0;
        [_remarksLabel setAttributedText:finalString withTruncation:NO];
        
        _remarksLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];

    }else {
        _remarksLabel.numberOfLines = 3;
        [_remarksLabel setText:str withTruncation:YES];
        _remarksLabel.textColor = [UIColor blackColor];
        
        _remarksLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0f];

    }
}

- (void)expandRemarksText
{
    [self configureText:[[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"] forExpandedState:YES];
}

- (void)collapseRemarksText
{
    [self configureText:[[_imagesArray objectAtIndex:_currentImageIndex] objectForKey:@"remarks"] forExpandedState:NO];
}

@end
