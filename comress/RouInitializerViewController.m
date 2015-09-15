//
//  RouInitializerViewController.m
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RouInitializerViewController.h"
#import "Synchronize.h"

@interface RouInitializerViewController ()

@end

@implementation RouInitializerViewController

@synthesize processLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    check_list              = [[Check_list alloc] init];
    check_area              = [[Check_area alloc] init];
    scan_check_list         = [[Scan_Check_list alloc] init];
    scan_check_list_block   = [[Scan_Check_List_Block alloc] init];
    job                     = [[Job alloc] init];
    schedule                = [[Schedule alloc] init];
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
    
    [self checkCheckListCount];
}

- (void)initializingCompleteWithUi:(BOOL)withUi
{
    //if(withUi == YES)
    myDatabase.initializingComplete = 1;
    myDatabase.userBlocksInitComplete = 1;
    myDatabase.userBlocksMappingInitComplete = YES;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        if([myDatabase setInitTo:1] == YES)
            [[NSNotificationCenter defaultCenter] postNotificationName:@"rouInitDone" object:nil];
    }];
}


#pragma mark - check if we need to download checklist
- (void)checkCheckListCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_checklist_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_checklist] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"CheckListContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            //save block count
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_checklist"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadCheckListForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkCheckAreaCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadCheckListForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading checklists page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_checklist] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CheckListContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"ListOfCheckList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSNumber *CheckListId = [NSNumber numberWithInt:[[dictList valueForKey:@"CheckListId"] intValue]];
            NSNumber *ChkAreaId = [NSNumber numberWithInt:[[dictList valueForKey:@"ChkAreaId"] intValue]];
            NSString *Item = [dictList valueForKey:@"Item"];
            NSNumber *JobTypeId = [NSNumber numberWithInt:[[dictList valueForKey:@"JobTypeId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsCheckCheckList = [theDb executeQuery:@"select * from ro_checklist where w_chklistid = ?",CheckListId];
                
                if([rsCheckCheckList next] == NO)
                {
                    BOOL ins = [theDb executeUpdate:@"insert into ro_checklist(w_chklistid,w_item,w_jobtypeid,w_chkareaid) values (?,?,?,?)",CheckListId,Item,JobTypeId,ChkAreaId];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCheckListForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [check_list updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkCheckAreaCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}




#pragma mark - check if we need to download checkarea
- (void)checkCheckAreaCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_checkarea_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_checkarea] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"CheckAreaContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_checkarea"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadCheckAreaForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkScanCheckListCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadCheckAreaForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading check area page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_checkarea] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CheckAreaContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"CheckAreaList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *ChkArea = [dictList valueForKey:@"ChkArea"];
            NSNumber *ChkAreaId = [NSNumber numberWithInt:[[dictList valueForKey:@"ChkAreaId"] intValue]];
            NSNumber *randomKey = [NSNumber numberWithInt:abs((int)arc4random())];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsCheckCheckArea = [theDb executeQuery:@"select * from ro_checkarea where w_chkareaid = ?",ChkAreaId];
                if([rsCheckCheckArea next] == NO)
                {
                    BOOL ins = [theDb executeUpdate:@"insert into ro_checkarea(w_chkareaid,w_chkarea,key) values (?,?,?)",ChkAreaId,ChkArea,randomKey];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCheckAreaForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [check_area updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkScanCheckListCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}



#pragma mark - check scan checklist
-(void)checkScanCheckListCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_scanchecklist_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_scan_checklist] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ScanCheckListContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_scanchecklist"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadScanCheckListForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkScanCheckListBlockCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadScanCheckListForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading scan checklist page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_scan_checklist] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ScanCheckListContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ListOfScanCheckList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *ItemFullName = [dictList valueForKey:@"ItemFullName"];
            NSString *ItemShortName = [dictList valueForKey:@"ItemShortName"];
            NSNumber *ScanChkListId = [NSNumber numberWithInt:[[dictList valueForKey:@"ScanChkListId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL ins = [theDb executeUpdate:@"insert into ro_scanchecklist(w_scanchklistid,w_itemshortname,w_itemfullname) values (?,?,?)",ScanChkListId,ItemShortName,ItemFullName];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadScanCheckListForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [scan_check_list updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkScanCheckListBlockCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}

#pragma mark - check for scan checklist block
- (void)checkScanCheckListBlockCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_scanchecklist_blk_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_scan_checklist_blk] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ScanCheckListContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_scanchecklist_blk"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadScanCheckListBlockForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self checkJobCount];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadScanCheckListBlockForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading check list block page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_scan_checklist_blk] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ScanCheckListContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ListOfScanCheckListBlk"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *Barcode = [dictList valueForKey:@"Barcode"];
            NSNumber *BlkId = [dictList valueForKey:@"BlkId"];
            NSNumber *ScanChkListBlkId = [dictList valueForKey:@"ScanChkListBlkId"];
            NSNumber *ScanChkListId = [dictList valueForKey:@"ScanChkListId"];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL ins = [theDb executeUpdate:@"insert into ro_scanchecklist_blk(w_scanchklistblkid,w_scanchklistid,w_blkid,w_barcode) values (?,?,?,?)",ScanChkListBlkId,ScanChkListId,BlkId,Barcode];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadScanCheckListBlockForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [scan_check_list_block updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkJobCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}



#pragma mark - check job count
- (void)checkJobCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_job_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_jobs] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"JobContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_job"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            

            if(needToDownloadBlocks)
                [self startDownloadJobsForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                DDLogVerbose(@"%@",[myDatabase.userDictionary valueForKey:@"group_name"]);
                if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SPO"])
                    [self checkSpoSkedCount];
                else
                    [self checkSupSkedCount];

            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadJobsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading jobs page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_jobs] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"JobContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ListOfScanCheckListBlk"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *Barcode = [dictList valueForKey:@"Barcode"];
            NSNumber *BlkId = [NSNumber numberWithInt:[[dictList valueForKey:@"BlkId"] intValue]];
            NSNumber *JobId = [NSNumber numberWithInt:[[dictList valueForKey:@"JobId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL ins = [theDb executeUpdate:@"insert into ro_job(w_jobid,w_blkid,w_barcode) values (?,?,?)",JobId,BlkId,Barcode];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadJobsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [job updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_NU"])
                [self checkSupSkedCount];
            else
                [self checkSpoSkedCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}


#pragma mark - check sup sked
- (void)checkSupSkedCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_schedule_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_sup_sked] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ScheduleContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_schedule"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadSupSkedForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SPO"])
                    [self checkSpoSkedCount];
                else
                    [self initializingCompleteWithUi:YES];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadSupSkedForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading schedule page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_sup_sked] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ScheduleContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ScheduleList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *Area          = [dictList valueForKey:@"Area"];
            NSNumber *BlkId         = [NSNumber numberWithInt:[[dictList valueForKey:@"BlkId"] intValue]];
            NSNumber *JobId         = [NSNumber numberWithInt:[[dictList valueForKey:@"JobId"] intValue]];
            NSString *JobType       = [dictList valueForKey:@"JobType"];;
            NSNumber *JobTypeId     = [NSNumber numberWithInt:[[dictList valueForKey:@"JobTypeId"] intValue]];
            NSDate *ScheduleDate    = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ScheduleDate"]];
            NSNumber *ScheduleId    = [NSNumber numberWithInt:[[dictList valueForKey:@"ScheduleId"] intValue]];
            NSDate *ActEndTime      = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ActEndTime"]];
            NSDate *ActStartTime    = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ActStartTime"]];
            NSDate *ActualDate      = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ActualDate"]];
            NSNumber *SUPFlag       = [NSNumber numberWithInt:[[dictList valueForKey:@"SUPFlag"] intValue]];
            NSDate *SupChk          = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"SupChk"]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                theDb.traceExecution = NO;
                FMResultSet *rs = [theDb executeQuery:@"select w_scheduleid from ro_schedule where w_scheduleid = ?",ScheduleId];
                
                if([rs next] == NO)//does not exist
                {
                    BOOL ins = [theDb executeUpdate:@"insert into ro_schedule (w_area,w_blkid,w_jobid,w_jobtype,w_jobtypeId,w_scheduledate,w_scheduleid,w_actendtime,w_actstarttime,w_actualdate,w_flag,w_supchk) values(?,?,?,?,?,?,?,?,?,?,?,?)",Area,BlkId,JobId,JobType,JobTypeId,ScheduleDate,ScheduleId,ActEndTime,ActStartTime,ActualDate,SUPFlag,SupChk];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSupSkedForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [schedule updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";

            [self prepareToDownloadSupActiveBlocks];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}



#pragma mark - check spo sked
- (void)checkSpoSkedCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from ro_schedule_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_spo_sked] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"ScheduleContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from ro_schedule"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];

            if(needToDownloadBlocks)
                [self startDownloadSpoSkedForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self initializingCompleteWithUi:YES];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self initializingCompleteWithUi:NO];
        }];
        
    }];
}


- (void)startDownloadSpoSkedForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading schedule page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_spo_sked] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ScheduleContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"ScheduleList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *Area          = [dictList valueForKey:@"Area"];
            NSNumber *BlkId         = [NSNumber numberWithInt:[[dictList valueForKey:@"BlkId"] intValue]];
            NSNumber *JobId         = [NSNumber numberWithInt:[[dictList valueForKey:@"JobId"] intValue]];
            NSString *JobType       = [dictList valueForKey:@"JobType"];
            NSNumber *JobTypeId     = [NSNumber numberWithInt:[[dictList valueForKey:@"JobTypeId"] intValue]];
            NSDate *ScheduleDate    = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ScheduleDate"]];
            NSNumber *ScheduleId    = [NSNumber numberWithInt:[[dictList valueForKey:@"ScheduleId"] intValue]];
            NSNumber *Flag          = [NSNumber numberWithInt:[[dictList valueForKey:@"Flag"] intValue]];
            NSDate *SPOChk          = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"SPOChk"]];

            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rs = [theDb executeQuery:@"select w_scheduleid from ro_schedule where w_scheduleid = ?",ScheduleId];
                
                if([rs next] == NO)//does not exist
                {
                    BOOL ins = [theDb executeUpdate:@"insert into ro_schedule (w_area,w_blkid,w_jobid,w_jobtype,w_jobtypeId,w_scheduledate,w_scheduleid,w_flag,w_spochk) values(?,?,?,?,?,?,?,?,?)",Area,BlkId,JobId,JobType,JobTypeId,ScheduleDate,ScheduleId,Flag,SPOChk];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSpoSkedForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [schedule updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self prepareToDownloadSupActiveBlocks];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}


- (void)prepareToDownloadSupActiveBlocks
{
    //check if the saved date is less than our current date. if so, delete from ro_sup_activeBlocks
    
    __block BOOL up;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        up = [db executeUpdate:@"delete from ro_sup_activeBlocks"];
        if(!up)
        {
            *rollback = YES;
            return;
        }
    }];
    
    if(up)
        [self startDownloadSupActiveBlocksForPage:1 totalPage:0 requestDate:nil withUi:YES];
}


- (void)startDownloadSupActiveBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading schedule page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_sup_active_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"SUPActiveBlockContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"SUPActiveBlockList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            
            NSDate *ActiveDate  = [myDatabase createNSDateWithWcfDateString:[dictList valueForKey:@"ActiveDate"]];
            NSNumber *BlkId     = [NSNumber numberWithInt:[[dictList valueForKey:@"BlkId"] intValue]];
            NSString *UserId    = [dictList valueForKey:@"UserName"];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                //db query and insert
                
                BOOL ins = [theDb executeUpdate:@"insert into ro_sup_activeBlocks (activeDate, block_id, user_id) values (?,?,?)",ActiveDate,BlkId,UserId];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSupActiveBlocksForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            self.processLabel.text = @"Download complete";
            
            [self initializingCompleteWithUi:YES];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:NO];
    }];
}


@end
