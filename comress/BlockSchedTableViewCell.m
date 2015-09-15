//
//  BlockSchedTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 3/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "BlockSchedTableViewCell.h"

@implementation BlockSchedTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateFormat = @"dd MMM";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
#if DEBUG
    double timeStamp = [[dict valueForKey:@"ScheduledDate"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSString *dateString = [_formatter stringFromDate:date];
    
    _blockNameLabel.text = [NSString stringWithFormat:@"%@-%@",[dict valueForKey:@"blockDesc"],dateString];
#else
    _blockNameLabel.text = [dict valueForKey:@"blockDesc"];
#endif
    
    _blocNotificationLabel.text = [dict valueForKey:@"Noti"];
    _numberOfJobsLabel.text = [NSString stringWithFormat:@"%d job(s)",[[dict valueForKey:@"TotalJob"] intValue]];
    
    BOOL IsUnlock = [[dict valueForKey:@"IsUnlock"] boolValue];
    
    UIImage *lock = [UIImage imageNamed:@"locked"];
    
    _unlockBlockButton.tag = 0;
    
    if(IsUnlock == YES)
    {
        lock = [UIImage imageNamed:@"arrow"];
        _unlockBlockButton.tag = 1;
    }

    [_unlockBlockButton setImage:lock forState:UIControlStateNormal];
    
    NSDate *now = [NSDate date];
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    NSDate *nowDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:24*00*00];
    double nowDateEpoch = [nowDate timeIntervalSince1970];
    
    if(timeStamp != nowDateEpoch)
        _unlockBlockButton.hidden = YES;
    else
        _unlockBlockButton.hidden = NO;
}

- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[jsonDateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    
    NSDate *date =  [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

@end
