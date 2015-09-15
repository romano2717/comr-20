//
//  NearbyLocationsViewController.h
//  comress
//
//  Created by Diffy Romano on 9/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ResidentInfoViewController;

@interface NearbyLocationsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{

}
@property (nonatomic, strong) ResidentInfoViewController *delegate;
@property (nonatomic, weak) IBOutlet UITableView *locationsTableView;

@property (nonatomic, strong) NSArray *foundPlacesArray;
@end
