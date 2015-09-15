//
//  IssuesPerPoTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 25/6/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomBadge.h"
#import "AppWideImports.h"

@interface IssuesPerPoTableViewCell : UITableViewCell
{
    CustomBadge *customBadge;
}

@property (nonatomic, weak) IBOutlet UILabel *poNameLabel;
@property (nonatomic, weak) IBOutlet UIView *messageCountBadge;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
