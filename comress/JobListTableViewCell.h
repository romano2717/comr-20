//
//  JobListTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"

@interface JobListTableViewCell : UITableViewCell
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UILabel *jobLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong)NSDateFormatter *formatter;

- (void)initCellWithResultSet:(NSDictionary *)dict;


@end
