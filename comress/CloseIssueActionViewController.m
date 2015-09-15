//
//  CloseIssueActionViewController.m
//  comress
//
//  Created by Diffy Romano on 11/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CloseIssueActionViewController.h"

@interface CloseIssueActionViewController ()

@end

@implementation CloseIssueActionViewController

@synthesize indexPath,status,calledFromList,dict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.selectedActionsArray = [[NSMutableArray alloc] init];
    
    self.actions = [NSArray arrayWithObjects:@"Site Inspection",@"Contact resident",@"Confirm with contractor", nil];
    
    //add border to the textview
    [[self.remarksTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.remarksTextView layer] setBorderWidth:1];
    [[self.remarksTextView layer] setCornerRadius:15];
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

- (IBAction)selectActionType:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    if([self.selectedActionsArray containsObject:tag] == NO)
    {
        [self.selectedActionsArray addObject:tag];
    }
    else
        [self.selectedActionsArray removeObject:tag];
    
    [btn setSelected:!btn.selected];
}

- (IBAction)submit:(id)sender
{
    NSString *remarks = [self.remarksTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(self.selectedActionsArray.count == 0 && remarks.length <= 3)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"COMRESS" message:@"Please select at least one action or provide your remarks in the text box." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alert show];
        
        return;
    }
    
    NSMutableString *actionsString = [[NSMutableString alloc] init];
    
    for (int i = 0; i < self.selectedActionsArray.count; i++) {
        int selectedActionsIndex = [[self.selectedActionsArray objectAtIndex:i] intValue] - 1;
        
        if(i == self.selectedActionsArray.count - 1) //last object
            [actionsString appendString:[NSString stringWithFormat:@"%@",[self.actions objectAtIndex:selectedActionsIndex]]];
        else
            [actionsString appendString:[NSString stringWithFormat:@"%@, ",[self.actions objectAtIndex:selectedActionsIndex]]];
    }
    
    
    if(calledFromList == 1)
    {
        NSDictionary *actionsDone = @{@"actionsTaken":actionsString,@"remarks":self.remarksTextView.text,@"indexPath":indexPath};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeIssueActionSubmitFromList" object:nil userInfo:actionsDone];
    }
    
    else
    {
        NSDictionary *chatDict = @{@"actionsTaken":actionsString,@"remarks":remarks,@"dict":dict,@"status":[NSNumber numberWithInt:status]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeIssueActionSubmitFromChat" object:nil userInfo:chatDict];
    }
    
}

- (IBAction)cancel:(id)sender
{
    if(calledFromList == 1)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeCloseIssueActionSubmitFromList" object:nil];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeCloseIssueActionSubmitFromChat" object:nil];
}

@end
