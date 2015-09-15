//
//  NearbyLocationsViewController.m
//  comress
//
//  Created by Diffy Romano on 9/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "NearbyLocationsViewController.h"
#import "ResidentInfoViewController.h"

@interface NearbyLocationsViewController ()

@end

@implementation NearbyLocationsViewController

@synthesize foundPlacesArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return foundPlacesArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *foundPlacesDict = [foundPlacesArray objectAtIndex:indexPath.row];
    
    cell.textLabel.minimumScaleFactor = 0.5f;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",[foundPlacesDict valueForKey:@"block_no"],[foundPlacesDict valueForKey:@"street_name"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Postal code: %@",[foundPlacesDict valueForKey:@"postal_code"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *row = [NSNumber numberWithInt:(int)indexPath.row];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectedTableRowLocation" object:nil userInfo:@{@"row":row}];
}


- (IBAction)cancel:(id)sender
{
    NSNumber *noBool = [NSNumber numberWithBool:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closePopUpWithLocationReload" object:nil userInfo:@{@"reload":noBool}];
}

- (IBAction)reloadLocationSearch:(id)sender
{
    NSNumber *yesBool = [NSNumber numberWithBool:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closePopUpWithLocationReload" object:nil userInfo:@{@"reload":yesBool}];
}

@end
