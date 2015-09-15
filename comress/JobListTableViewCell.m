//
//  JobListTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "JobListTableViewCell.h"

@implementation JobListTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    myDatabase = [Database sharedMyDbManager];
    
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateFormat = @"dd MMM";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    _jobLabel.text = [dict valueForKey:@"JobType"];
    
    int status = [[dict valueForKey:@"Status"] intValue];
    
    NSString *statusString;
    
    //Status (1 for New , 2 for Started, 3 for Completed)
    
    switch (status) {
        case 2:
            statusString = @"Status: Started";
            break;
        case 3:
            statusString = @"Status: Completed";
            break;
            
        default:
            statusString = @"Status: New";
            break;
    }
    _statusLabel.text = statusString;
    
    
    NSString *ScheduleDateString = [dict valueForKey:@"ScheduleDate"];
    NSDate *ScheduleDate = [myDatabase createNSDateWithWcfDateString:ScheduleDateString];
    NSString *dateString = [_formatter stringFromDate:ScheduleDate];
    
    _dateLabel.text = dateString;
}

@end
