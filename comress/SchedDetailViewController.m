//
//  SchedDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SchedDetailViewController.h"

@interface SchedDetailViewController ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate,UINavigationControllerDelegate,UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *scheduleDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UITableView *imagesTableView;
@property (nonatomic, weak) IBOutlet UITextView *remarksTextView;
@property (nonatomic, weak) IBOutlet UIButton *okButton;

@property (nonatomic, strong) NSDictionary *scheduleDetailDictionary;
@property (nonatomic, strong) NSArray *imageTemplate;
@property (nonatomic, strong) NSArray *ImageList;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong) NSDictionary *selectedImageTemplateDict;

@property (nonatomic)  int imageType; //1: before, 2: after

@property (nonatomic) int scheduleImagePairCounter;

@end

@implementation SchedDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    /**********/
    
//    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
//        [db executeUpdate:@"delete from rt_checklist"];
//        [db executeUpdate:@"delete from rt_imageTemplate"];
//        [db executeUpdate:@"delete from rt_schedule_detail"];
//        [db executeUpdate:@"delete from rt_schedule_image"];
//    }];
    /**********/
    
    [self getScheduleDetail];
    
    //add border to remarks textview
    [[_remarksTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[_remarksTextView layer] setBorderWidth:1];
    [[_remarksTextView layer] setCornerRadius:15];
    
    [[_imagesTableView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[_imagesTableView layer] setBorderWidth:1];
    [[_imagesTableView layer] setCornerRadius:15];
    
    self.lastVisibleView = _okButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(retrieveLocalScheduleDetail) name:@"retrieveLocalScheduleDetail" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"push_image_preview_caption"])
    {
        ImageCaptionViewController *imgCaptionVC = [segue destinationViewController];
        imgCaptionVC.scheduleDetailDict = sender;
    }
    else if ([segue.identifier isEqualToString:@"push_image_viewer"])
    {
        ImageViewerViewController *imageViewer = [segue destinationViewController];
        imageViewer.imageTemplateDict = sender;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:[_jobDetailDict valueForKey:@"blockDesc"]];
    [navigationBarTitleView setDetailText:[_jobDetailDict valueForKey:@"JobType"]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)retrieveLocalScheduleDetail
{
    //get schedule from local db
    
    NSMutableDictionary *mutScheduleDict = [[NSMutableDictionary alloc] init];
    
    //store non existing image
    NSMutableArray *imagesDoesNotExistArray = [[NSMutableArray alloc] init];
    
    _scheduleImagePairCounter = 0;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSNumber *theSelectedScheduleId = [NSNumber numberWithInt:[[_jobDetailDict valueForKey:@"ScheduleId"] intValue]];
        
        FMResultSet *rsCheckListArray = [db executeQuery:@"select * from rt_checklist where schedule_id = ?",theSelectedScheduleId];
        NSMutableArray *CheckListArray = [[NSMutableArray alloc] init];
        
        while ([rsCheckListArray next]) {
            NSString *CheckArea = [rsCheckListArray stringForColumn:@"checkarea"];
            NSNumber *CheckListId = [NSNumber numberWithInt:[rsCheckListArray intForColumn:@"checklist_id"]];
            NSString *CheckListName = [rsCheckListArray stringForColumn:@"checklist_name"];;
            NSNumber *IsCheck = [NSNumber numberWithBool:[rsCheckListArray boolForColumn:@"is_checked"]];
            NSNumber *ScheduleId = [NSNumber numberWithInt:[rsCheckListArray intForColumn:@"schedule_id"]];
            
            NSDictionary *dict = @{@"CheckArea":CheckArea,@"CheckListId":CheckListId,@"CheckListName":CheckListName,@"IsCheck":IsCheck,@"ScheduleId":ScheduleId};
            
            [CheckListArray addObject:dict];
        }
        
        
        FMResultSet *rsImageList = [db executeQuery:@"select * from rt_schedule_image where schedule_id = ? order by client_schedule_image_id desc",theSelectedScheduleId];
        NSMutableArray *ImageListArray = [[NSMutableArray alloc] init];
        
        while ([rsImageList next]) {
            NSNumber *CheckListId = [NSNumber numberWithInt:[rsImageList intForColumn:@"checklist_id"]];
            NSString *ImageName = [rsImageList stringForColumn:@"image_name"];
            NSNumber *ImageType = [NSNumber numberWithInt:[rsImageList intForColumn:@"image_type"]];
            NSString *Remark = [rsImageList stringForColumn:@"remark"];
            NSNumber *ScheduleId = [NSNumber numberWithInt:[rsImageList intForColumn:@"schedule_id"]];
            NSNumber *ScheduleImageId = [NSNumber numberWithInt:[rsImageList intForColumn:@"schedule_image_id"]];
            
            NSDictionary *dict = @{@"CheckListId":CheckListId,@"ImageName":ImageName,@"ImageType":ImageType,@"Remark":Remark,@"ScheduleId":ScheduleId,@"ScheduleImageId":ScheduleImageId};
            
            [ImageListArray addObject:dict];
            
            
            //check if this image exists in phone's disk, if not, download it!
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:ImageName];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
            {
                [imagesDoesNotExistArray addObject:@{@"ImageList":[rsImageList resultDictionary]}];
            }
        }
        
        
        FMResultSet *rsImageTemplate = [db executeQuery:@"select * from rt_imageTemplate where ScheduleId = ?",theSelectedScheduleId];
        NSMutableArray *ImageTemplateArray = [[NSMutableArray alloc] init];
        
        while ([rsImageTemplate next]) {
            NSNumber *CheckListId = [NSNumber numberWithInt:[rsImageTemplate intForColumn:@"CheckListId"]];
            NSNumber *MinNoOfImage = [NSNumber numberWithInt:[rsImageTemplate intForColumn:@"MinNoOfImage"]];
            NSNumber *ScheduleId = [NSNumber numberWithInt:[rsImageTemplate intForColumn:@"ScheduleId"]];
            NSString *Title = [rsImageTemplate stringForColumn:@"Title"];
            
            NSNumber *beforeImageType = [NSNumber numberWithInt:1];
            NSNumber *afterImageType = [NSNumber numberWithInt:2];
            
            //get the number of images added for this checklist per pair

            FMResultSet *rsGetPairPerChecklistForBeforeImg = [db executeQuery:@"select count (*) as beforePair from rt_schedule_image where schedule_id = ? and checklist_id = ? and image_type = ?",theSelectedScheduleId,CheckListId,beforeImageType];
            
            FMResultSet *rsGetPairPerChecklistForAfterImg = [db executeQuery:@"select count (*) as afterPair from rt_schedule_image where schedule_id = ? and checklist_id = ? and image_type = ?",theSelectedScheduleId,CheckListId,afterImageType];

            
            int beforeImagesPair = 0;
            int afterImagesPair = 0;
            
            while ([rsGetPairPerChecklistForBeforeImg next]) {
                beforeImagesPair = [rsGetPairPerChecklistForBeforeImg intForColumn:@"beforePair"];
            }
            
            while ([rsGetPairPerChecklistForAfterImg next]) {
                afterImagesPair = [rsGetPairPerChecklistForAfterImg intForColumn:@"afterPair"];
            }
            
            NSDictionary *dict = @{@"CheckListId":CheckListId,@"MinNoOfImage":MinNoOfImage,@"ScheduleId":ScheduleId,@"Title":Title,@"beforeImagesPair":[NSNumber numberWithInt:beforeImagesPair],@"afterImagesPair":[NSNumber numberWithInt:afterImagesPair]};
            
            [ImageTemplateArray addObject:dict];
        }
        
        
        FMResultSet *rsScheduleDetail = [db executeQuery:@"select * from rt_schedule_detail where schedule_id = ?",theSelectedScheduleId];
        NSMutableDictionary *SUPSchedule = [[NSMutableDictionary alloc] init];
        
        NSDictionary *imageConfig;
        
        while ([rsScheduleDetail next]) {
            NSString *Area = [rsScheduleDetail stringForColumn:@"area"];
            NSString *JobType = [rsScheduleDetail stringForColumn:@"job_type"];
            NSNumber *JobTypeId = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"job_type_id"]];
            NSString *Message = [rsScheduleDetail stringForColumn:@"message"] ? [rsScheduleDetail stringForColumn:@"message"] : @"" ;
            NSString *Remarks = [rsScheduleDetail stringForColumn:@"remarks"];
            NSString *ScheduleDate = [myDatabase createWcfDateWithNsDate:[rsScheduleDetail dateForColumn:@"schedule_date"]];
            NSNumber *ScheduleId = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"schedule_id"]];
            NSNumber *Status = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"status"]];
            NSString *UpdatedBy = [rsScheduleDetail stringForColumn:@"updated_by"];
            NSString *UpdatedDate = [myDatabase createWcfDateWithNsDate:[rsScheduleDetail dateForColumn:@"updated_date"]];
            
            NSNumber *MinNumberOfImage = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"MinNumberOfImage"]];
            NSNumber *MinNumberOfPair = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"MinNumberOfPair"]];
            NSNumber *imageStatus = [NSNumber numberWithInt:[rsScheduleDetail intForColumn:@"imageStatus"]];
            
            [SUPSchedule setObject:Area forKey:@"Area"];
            [SUPSchedule setObject:JobType forKey:@"JobType"];
            [SUPSchedule setObject:JobTypeId forKey:@"JobTypeId"];
            [SUPSchedule setObject:Message forKey:@"Message"];
            [SUPSchedule setObject:Remarks forKey:@"Remarks"];
            [SUPSchedule setObject:ScheduleDate forKey:@"ScheduleDate"];
            [SUPSchedule setObject:ScheduleId forKey:@"ScheduleId"];
            [SUPSchedule setObject:Status forKey:@"Status"];
            [SUPSchedule setObject:UpdatedBy forKey:@"UpdatedBy"];
            [SUPSchedule setObject:UpdatedDate forKey:@"UpdatedDate"];
            
            imageConfig = @{@"MinNumberOfImage":MinNumberOfImage,@"MinNumberOfPair":MinNumberOfPair,@"Status":imageStatus};
        }
        
        [mutScheduleDict setObject:CheckListArray forKey:@"CheckListArray"];
        [mutScheduleDict setObject:imageConfig forKey:@"ImageConfig"];
        [mutScheduleDict setObject:ImageListArray forKey:@"ImageList"];
        [mutScheduleDict setObject:ImageTemplateArray forKey:@"ImageTemplate"];
        [mutScheduleDict setObject:SUPSchedule forKey:@"SUPSchedule"];
        [mutScheduleDict setObject:[_scheduleDetailDictionary valueForKey:@"HasChanges"] forKey:@"HasChanges"];
        
        
        //get the  number of paired images for this schedule
        NSArray *theChecklistArray = [mutScheduleDict objectForKey:@"CheckListArray"];
        
        for (NSDictionary *dict in theChecklistArray) {
            NSNumber *checklistId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
            
            NSNumber *beforeImageType = [NSNumber numberWithInt:1];
            NSNumber *afterImageType = [NSNumber numberWithInt:2];
            
            FMResultSet *rsCheckForBeforeImg = [db executeQuery:@"select * from rt_schedule_image where schedule_id = ? and checklist_id = ? and image_type = ?",theSelectedScheduleId,checklistId,beforeImageType];
            
            FMResultSet *rsCheckForAfterImg = [db executeQuery:@"select * from rt_schedule_image where schedule_id = ? and checklist_id = ? and image_type = ?",theSelectedScheduleId,checklistId,afterImageType];
            

            if([rsCheckForBeforeImg next] && [rsCheckForAfterImg next])
                _scheduleImagePairCounter++;
        }
    }];
    
    if(imagesDoesNotExistArray.count > 0)
        [self downloadImages:imagesDoesNotExistArray];

    //prepare data for ui
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _scheduleDetailDictionary = mutScheduleDict;
        //DDLogVerbose(@"%@",_scheduleDetailDictionary);
        
        //SCHEDULE DATE
        NSDate *ScheduleDate = [myDatabase createNSDateWithWcfDateString:[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"ScheduleDate"]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"dd/MM/YYYY";
        
#if DEBUG
        NSString *dateString = [NSString stringWithFormat:@"%@|%@|%@",[formatter stringFromDate:ScheduleDate],[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"ScheduleId"],[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"Status"]];
#else
        NSString *dateString = [formatter stringFromDate:ScheduleDate];
#endif
        
        
        //SCHEDULE UPDATE DATE
        NSDate *UpdatedDate = [myDatabase createNSDateWithWcfDateString:[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"UpdatedDate"]];
        NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
        formatter2.dateFormat = @"dd/MM";
        NSString *dateString2 = [formatter2 stringFromDate:UpdatedDate];
        
        NSString *UpdatedBy = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"UpdatedBy"];
        
        //STATUS
        int status = [[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Status"] intValue];
        NSString *statusString = [NSString stringWithFormat:@"NEW at %@ by %@,",dateString2,UpdatedBy];
        
        switch (status) {
            case 2:
                statusString = [NSString stringWithFormat:@"START at %@ by %@",dateString2,UpdatedBy];
                break;
                
            case 3:
                statusString = [NSString stringWithFormat:@"COMPLETE at %@ by %@",dateString2,UpdatedBy];
                break;
        }
        
        
        //PHOTO COUNT
        int MinNumberOfPair = [[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"MinNumberOfPair"] intValue];
        int MinNumberOfImage = [[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"MinNumberOfImage"] intValue];
        int scheduleImageStatus = [[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"Status"] intValue];
        
        if(scheduleImageStatus != 1)
        {
            NSString *photoCount = [NSString stringWithFormat:@"%d/%d Photo pairs",_scheduleImagePairCounter,MinNumberOfPair];
            
            [_cameraButton setTitle:photoCount forState:UIControlStateNormal];
        }
        
        
        
        //REMARKS
        NSString *remarks = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Remarks"];
        
        
        //set ui
        _scheduleDateLabel.text = [NSString stringWithFormat:@"Date: %@",dateString];
        _statusLabel.text = [NSString stringWithFormat:@"Status: %@",statusString];
        _remarksTextView.text = remarks;
        
        
        //table view
        [_imagesTableView reloadData];
    });
}

- (void)downloadImages:(NSArray *)array
{
    int x = 1;
    for (NSDictionary *dict in array) {
        SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
        
        NSDictionary *theDict = [dict objectForKey:@"ImageList"];
        
        NSNumber *checklist_id = [NSNumber numberWithInt:[[theDict valueForKey:@"checklist_id"] intValue]];
        NSNumber *client_schedule_image_id = [NSNumber numberWithInt:[[theDict valueForKey:@"client_schedule_image_id"] intValue]];
        NSString *image_name = [theDict valueForKey:@"image_name"];
        NSNumber *schedule_id = [NSNumber numberWithInt:[[theDict valueForKey:@"schedule_id"] intValue]];
        
        NSString *imageUrl = [NSString stringWithFormat:@"%@ComressMImage/schedule/%@/%@",myDatabase.domain,schedule_id,image_name];
        
        [sd_manager downloadImageWithURL:[NSURL URLWithString:imageUrl] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if(image == nil)
            {
                DDLogVerbose(@"404 %@",imageURL);
                return;
            }
            
            
            //create the image here
            NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
            
            //save the image to app documents dir
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            
            NSString *filePath = [documentsPath stringByAppendingPathComponent:image_name]; //Add the file name
            [jpegImageData writeToFile:filePath atomically:YES];
            
            NSFileManager *fManager = [[NSFileManager alloc] init];
            if([fManager fileExistsAtPath:filePath] == NO)
                return;
            
            //resize the saved image
            [imgOpts resizeImageAtPath:filePath];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                BOOL up = [db executeUpdate:@"update rt_schedule_image set image_name = ? where checklist_id = ? and schedule_id = ? and client_schedule_image_id = ?",image_name,checklist_id,schedule_id,client_schedule_image_id];
                
                if(!up)
                {
                    *rollback = YES;
                    return;
                }
            }];
            
            if(x == array.count)
                [self retrieveLocalScheduleDetail];
        }];
        x++;
    }
}

- (void)getScheduleDetail
{
    NSDictionary *params = @{@"scheduleId":[_jobDetailDict valueForKey:@"ScheduleId"],@"ignoreCache":[NSNumber numberWithBool:NO]};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url ,api_get_schedule_detail_by_sup] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        _scheduleDetailDictionary = [responseObject objectForKey:@"ScheduleDetail"];
        BOOL HasChanges = [[[responseObject objectForKey:@"ScheduleDetail"] valueForKey:@"HasChanges"] boolValue];
        
        if(HasChanges == YES)
        {
            [self saveOrUpdateScheduleToDb];
        }
        else
            [self retrieveLocalScheduleDetail];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self getScheduleDetail];
    }];
}

- (void)saveOrUpdateScheduleToDb
{
    //save to db
    NSNumber *scheduleId = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"ScheduleId"] intValue]];
    NSString *area = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Area"];
    NSString *JobType = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"JobType"];
    NSString *Message = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Message"];
    NSNumber *JobTypeId = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"JobTypeId"] intValue]];
    NSDate *ScheduleDateNsDate = [myDatabase createNSDateWithWcfDateString:[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"ScheduleDate"]];
    NSString *Remarks = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Remarks"];
    NSNumber *Status = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"Status"] intValue]];
    NSString *UpdatedByString = [[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"UpdatedBy"];
    NSDate *UpdatedDateNsDate = [myDatabase createNSDateWithWcfDateString:[[_scheduleDetailDictionary objectForKey:@"SUPSchedule"] valueForKey:@"UpdatedDate"]];
    NSNumber *MinNumberOfImage = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"MinNumberOfImage"] intValue]] ;
    NSNumber *MinNumberOfPair = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"MinNumberOfPair"] intValue]] ;
    NSNumber *imageStatus = [NSNumber numberWithInt:[[[_scheduleDetailDictionary objectForKey:@"ImageConfig"] valueForKey:@"Status"] intValue]] ;
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        //schedule
        BOOL ins = NO;
        
        FMResultSet *rsChecSched = [db executeQuery:@"select schedule_id from rt_schedule_detail where schedule_id = ?",scheduleId];
        
        if([rsChecSched next] == NO)
        {
            ins = [db executeUpdate:@"insert into rt_schedule_detail (schedule_id, area, job_type, job_type_id, schedule_date, remarks, status, updated_by, updated_date, message, MinNumberOfImage, MinNumberOfPair, imageStatus ) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",scheduleId,area,JobType,JobTypeId,ScheduleDateNsDate,Remarks,Status,UpdatedByString,UpdatedDateNsDate,Message,MinNumberOfImage,MinNumberOfPair,imageStatus];
        }
        else
        {
            ins = [db executeUpdate:@"update rt_schedule_detail set schedule_id = ?, area = ?, job_type = ?, job_type_id = ?, schedule_date = ?, remarks = ?, status = ?, updated_by = ?, updated_date = ?, message = ?, MinNumberOfImage = ?, MinNumberOfPair = ?, imageStatus = ? where schedule_id = ?",scheduleId,area,JobType,JobTypeId,ScheduleDateNsDate,Remarks,Status,UpdatedByString,UpdatedDateNsDate,Message,MinNumberOfImage,MinNumberOfPair,imageStatus,scheduleId];
        }
        
        
        if(!ins)
        {
            *rollback = YES;
            return;
        }
        else
        {
            //checklist
            for (NSDictionary *dict in [_scheduleDetailDictionary objectForKey:@"CheckListArray"]) {
                NSString *CheckArea = [dict valueForKey:@"CheckArea"];
                NSNumber *CheckListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
                NSString *CheckListName = [dict valueForKey:@"CheckListName"];
                NSNumber *IsCheck = [NSNumber numberWithBool:[[dict valueForKey:@"IsCheck"] boolValue]];
                NSNumber *ScheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleId"] intValue]];
                
                BOOL ins = NO;
                
                FMResultSet *rsCheckChecklist = [db executeQuery:@"select checklist_id from rt_checklist where checklist_id = ? and schedule_id = ?",CheckListId,ScheduleId];
                
                if([rsCheckChecklist next] == NO)
                {
                    ins = [db executeUpdate:@"insert into rt_checklist (checklist_id, checklist_name, checkarea, is_checked, schedule_id) values (?,?,?,?,?)",CheckListId,CheckListName,CheckArea,IsCheck,ScheduleId];
                }
                else
                {
                    ins = [db executeUpdate:@"update rt_checklist set checklist_id = ?, checklist_name = ?, checkarea = ?, is_checked = ?, schedule_id = ? where checklist_id = ? and schedule_id = ?",CheckListId,CheckListName,CheckArea,IsCheck,ScheduleId,CheckListId,ScheduleId];
                }
                
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            //images
            for (NSDictionary *dict in [_scheduleDetailDictionary objectForKey:@"ImageList"]) {
                NSNumber *CheckListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
                NSString *ImageName = [dict valueForKey:@"ImageName"];
                NSNumber *ImageType = [NSNumber numberWithInt:[[dict valueForKey:@"ImageType"] intValue]];
                NSString *Remark = [dict valueForKey:@"Remark"];
                NSNumber *ScheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleId"] intValue]];
                NSNumber *ScheduleImageId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleImageId"] intValue]];
                
                BOOL ins = NO;
                
                FMResultSet *rsCheckScheduleImage = [db executeQuery:@"select schedule_image_id from rt_schedule_image where schedule_image_id = ? and schedule_id = ?  and checklist_id = ?",ScheduleImageId,ScheduleId,CheckListId,ImageName];
                
                if([rsCheckScheduleImage next] == NO)
                {
                    ins = [db executeUpdate:@"insert into rt_schedule_image (schedule_image_id, schedule_id, checklist_id, image_name, image_type, remark) values (?,?,?,?,?,?)", ScheduleImageId,ScheduleId,CheckListId,ImageName,ImageType,Remark];
                }
                else
                {
                    ins = [db executeUpdate:@"update rt_schedule_image set schedule_image_id = ?, schedule_id = ?, checklist_id = ?, image_type = ?, remark = ? where schedule_image_id = ? and schedule_id = ?  and checklist_id = ? and image_name = ?",ScheduleImageId,ScheduleId,CheckListId,ImageType,Remark,ScheduleImageId,ScheduleId,CheckListId,ImageName];
                }
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            //images template
            for (NSDictionary *dict in [_scheduleDetailDictionary objectForKey:@"ImageTemplate"]) {
                NSNumber *CheckListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
                NSNumber *MinNoOfImage = [NSNumber numberWithInt:[[dict valueForKey:@"MinNoOfImage"] intValue]];
                NSNumber *ScheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleId"] intValue]];
                NSString *Title = [dict valueForKey:@"Title"];
                
                BOOL ins = NO;
                
                FMResultSet *rsCheckImageTemplate = [db executeQuery:@"select CheckListId from rt_imageTemplate where CheckListId = ? and ScheduleId = ?",CheckListId,ScheduleId];
                
                if([rsCheckImageTemplate next] == NO)
                {
                    ins = [db executeUpdate:@"insert into rt_imageTemplate (CheckListId, MinNoOfImage, ScheduleId, Title) values (?,?,?,?)",CheckListId,MinNoOfImage,ScheduleId,Title];
                }
                else
                {
                    ins = [db executeUpdate:@"update rt_imageTemplate set CheckListId = ?, MinNoOfImage = ?, ScheduleId = ?, Title = ? where CheckListId = ? and ScheduleId = ?",CheckListId,MinNoOfImage,ScheduleId,Title,CheckListId,ScheduleId];
                }
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }
        }
    }];
    
    [self retrieveLocalScheduleDetail];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"theCell";
    
    ScheduleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *dict = @{@"ImageTemplate":[[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] objectAtIndex:indexPath.row],@"Images":[_scheduleDetailDictionary objectForKey:@"ImageList"]};

    [cell initCellWithResultSet:dict];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedImageTemplateDict = [[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] objectAtIndex:indexPath.row];
    
    //imageType = 0: all pictures under this checklist
    NSDictionary *dict = @{@"imageType":[NSNumber numberWithInt:0],@"imageTemplate":_selectedImageTemplateDict,@"jobDesc":_jobDetailDict};
    [self performSegueWithIdentifier:@"push_image_viewer" sender:dict];
}

- (IBAction)addMorePhotos:(id)sender
{
    UITapGestureRecognizer *tap = sender;
    
    UIView* view = tap.view;

    UILabel *label = (UILabel *)view;
    
    CGPoint location = [tap locationInView:_imagesTableView];
    NSIndexPath *indexPath = [_imagesTableView indexPathForRowAtPoint:location];
    
    _imageType = (int)label.tag;
    
    _selectedImageTemplateDict = [[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] objectAtIndex:indexPath.row];
    
    if(_imageType == 1 || _imageType == 2) //add photo
    {
        [self openMediaByType:1];
    }
}

- (IBAction)viewPhotos:(id)sender
{
    UIButton *btn = sender;
    NSIndexPath *indexPath = [_imagesTableView indexPathForCell:(UITableViewCell *)btn.superview.superview];
    
    _imageType = (int)btn.tag;
    
    if (_imageType == 1 || _imageType == 2) //view images
    {
        _selectedImageTemplateDict = [[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] objectAtIndex:indexPath.row];
        
        NSDictionary *dict = @{@"imageType":[NSNumber numberWithInt:_imageType],@"imageTemplate":_selectedImageTemplateDict,@"jobDesc":_jobDetailDict};
        [self performSegueWithIdentifier:@"push_image_viewer" sender:dict];
    }
    else if(_imageType == 3 || _imageType == 4) //add images
    {
        NSIndexPath *indexPath = [_imagesTableView indexPathForCell:(UITableViewCell *)btn.superview.superview];
        
        _imageType = (int)btn.tag;
        _imageType -= 2;
        
        _selectedImageTemplateDict = [[_scheduleDetailDictionary objectForKey:@"ImageTemplate"] objectAtIndex:indexPath.row];

        [self openMediaByType:1];
    }

}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self openMediaByType:1];
            break;
            
        case 1:
            [self openMediaByType:2];
            break;
    }
    
    [self.view endEditing:YES];
}

#pragma mark image picker
- (void)openMediaByType:(int)type
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    if (type == 1)
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
    
    self.imagePicker = picker;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if(img == nil)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if(imgOpts == nil)
        imgOpts = [ImageOptions new];
    
    UIImage *thumbImage = [imgOpts resizeImageAsThumbnailForImage:img];
    
    NSDictionary *dict = @{@"image":thumbImage,@"_selectedImageTemplateDict":_selectedImageTemplateDict,@"imageType":[NSNumber numberWithInt:_imageType]};

    [self performSegueWithIdentifier:@"push_image_preview_caption" sender:dict];
}

@end
