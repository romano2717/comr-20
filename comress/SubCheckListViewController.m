//
//  SubCheckListViewController.m
//  comress
//
//  Created by Diffy Romano on 28/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SubCheckListViewController.h"

@interface SubCheckListViewController ()

@end

@implementation SubCheckListViewController

@synthesize checkListArray,checkListableView,dict,updatedCheckList,selectedCheckList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    check_list = [[Check_list alloc] init];
    
    NSNumber *checkAreaId = [dict valueForKey:@"checkAreaId"];
    NSNumber *jobTypeId = [dict valueForKey:@"jobTypeId"];
    
    checkListArray = [check_list checkListForCheckAreaId:checkAreaId JobTypeId:jobTypeId];
    
    selectedCheckList = [[NSMutableArray alloc] init];
    
    updatedCheckList = [check_list updatedChecklist];
    NSMutableArray *upd = [[NSMutableArray alloc] init];
    for (int i = 0; i < updatedCheckList.count; i ++) {
        NSDictionary *theDict = [updatedCheckList objectAtIndex:i];
        
        NSNumber *w_checklistid = [NSNumber numberWithInt:[[theDict valueForKey:@"w_checklistid"] intValue]];
        
        [upd addObject:w_checklistid];
    }
    updatedCheckList = upd;
    
    [self fetchCheckList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = [dict valueForKey:@"checkAreaName"];
    
    [checkListableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return checkListArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    SubCheckListTableViewCell *sbvc = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDictionary *cellDict = [checkListArray objectAtIndex:indexPath.row];
    
    [sbvc initCellWithResultSet:cellDict];
    
    NSNumber *w_chklistid = [NSNumber numberWithInt:[[cellDict valueForKey:@"w_chklistid"] intValue]];
    if([updatedCheckList containsObject:w_chklistid])
    {
        [sbvc.checkBoxBtn setSelected:YES];
    }
    
    return sbvc;
}

- (void)fetchCheckList
{

}

@end
