//
//  IssueListPerPoViewController.m
//  comress
//
//  Created by Diffy Romano on 22/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssueListPerPoViewController.h"

@interface IssueListPerPoViewController ()

@end

@implementation IssueListPerPoViewController

@synthesize poDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:[poDict valueForKey:@"user"]];
    [navigationBarTitleView setDetailText:[poDict valueForKey:@"division"]];
    
    self.pOIssuesTableView.estimatedRowHeight = 115.0;
    self.pOIssuesTableView.rowHeight = UITableViewAutomaticDimension;
    
    post = [[Post alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didDismissJSQMessageComposerViewController:(IssuesChatViewController *)vc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSNumber *postId;
    NSDictionary *dict;
    
    if([sender isKindOfClass:[NSIndexPath class]])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;

        dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        postId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
    }

    if([segue.identifier isEqualToString:@"push_chat_issues"])
    {
        self.tabBarController.tabBar.hidden = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBar.hidden = NO;
        
        int ServerPostId = 0;

        if([[[dict objectForKey:postId] objectForKey:@"post"] valueForKey:@"post_id"] != [NSNull null])
            ServerPostId = [[[[dict objectForKey:postId] objectForKey:@"post"] valueForKey:@"post_id"] intValue];
        
        BOOL isFiltered = NO;
        
        BOOL hideActionStatusBtn = YES;
        
        if([[myDatabase.userDictionary valueForKey:@"group_name"] rangeOfString:@"CT"].location != NSNotFound)
            hideActionStatusBtn = NO;
        
        IssuesChatViewController *issuesVc = [segue destinationViewController];
        issuesVc.postId = [postId intValue];
        issuesVc.isFiltered = isFiltered;
        issuesVc.delegateModal = self;
        issuesVc.ServerPostId = ServerPostId;
        issuesVc.hideActionStatusBtn = hideActionStatusBtn;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.pOIssuesTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.postsArray = [post fetchIssuesForPO:[poDict valueForKey:@"user"] division:[poDict valueForKey:@"division"]];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return self.postsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    @try {
        
        static NSString *nonPmCellIdentifier = @"cell";
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        IssuesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nonPmCellIdentifier forIndexPath:indexPath];
    
        [cell initCellWithResultSet:dict forSegment:1];
    
        return cell;

    }
    @catch (NSException *exception) {
        DDLogVerbose(@"cellForRowAtIndexPath exception: %@ [%@-%@]",exception,THIS_FILE,THIS_METHOD);
    }
    @finally {
        
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_chat_issues" sender:indexPath];
}



@end
