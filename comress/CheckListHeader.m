//
//  CheckListHeader.m
//  comress
//
//  Created by Diffy Romano on 20/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListHeader.h"

@implementation CheckListHeader

@synthesize checkListLabel,saveBtn,finishBtn;

- (void)awakeFromNib {
    // Initialization code
    
    myDatabase = [Database sharedMyDbManager];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    self.checkListLabel.text = [dict valueForKey:@"w_jobtype"];
    
    NSDate *scheduleDate = [NSDate dateWithTimeIntervalSince1970:[[dict valueForKey:@"w_scheduledate"] doubleValue]];
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    NSString *datestring = [format stringFromDate:scheduleDate];
    
    self.scheduleDate.text = datestring;
    
//    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"SPO"])
//    {
//    
//    }
//    else
//    {
////        if([[dict valueForKey:@"w_supflag"] intValue] == 2) //finished
////        {
////            saveBtn.hidden = YES;
////            finishBtn.hidden = YES;
////        }
//    }
}

@end
