//
//  PostStatusTableViewController.m
//  comress
//
//  Created by Diffy Romano on 15/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostStatusTableViewController.h"
#import "IssuesChatViewController.h"
#import "Database.h"

@interface PostStatusTableViewController ()
{
    Database *myDatabase;
}
@property (nonatomic, strong)NSArray *status;

@end

@implementation PostStatusTableViewController

@synthesize delegate=_delegate,selectedStatus,actionsAreRequired;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    myDatabase = [Database sharedMyDbManager];
    
    post = [[Post alloc] init];
    
    NSArray *allowedActions = [[post getAvailableActions] valueForKey:@"ActionValue"];
    NSArray *nextActionsForCurrentAction = [post getActionSequenceForCurrentAction:[selectedStatus intValue]];
    
    NSMutableArray *allowedActionsMutable = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < nextActionsForCurrentAction.count; i++) {
        
        NSNumber *nextAction = [NSNumber numberWithInt:[[[nextActionsForCurrentAction objectAtIndex:i] valueForKey:@"NextAction"] intValue]];
        
        if([allowedActions containsObject:nextAction] == NO)
            continue;
        else
            [allowedActionsMutable addObject:[nextActionsForCurrentAction objectAtIndex:i]];
    }
    
    self.status = allowedActionsMutable;
    
    if(self.status.count == 0 || actionsAreRequired == NO)
    {
        self.status = nil;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.view.frame), 20)];
        label.text = @"Actions none required";
        
        [self.view addSubview:label];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.status.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static  NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [[self.status objectAtIndex:indexPath.row] valueForKey:@"NextActionName"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *statusSelectedDict = [self.status objectAtIndex:indexPath.row];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectedTableRow" object:nil userInfo:statusSelectedDict];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
