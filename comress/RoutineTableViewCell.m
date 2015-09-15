//
//  RoutineTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineTableViewCell.h"

@implementation RoutineTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict postDict:(NSDictionary *)postDict
{
    NSString *blockNo = [dict valueForKey:@"block_no"];
    NSString *streetName = [dict valueForKey:@"street_name"];

    NSString *key = [[postDict allKeys] firstObject];
    NSDictionary *latestComment = [[[postDict objectForKey:key] objectForKey:@"postComments"] firstObject];
    int newCommentsCount = [[[postDict objectForKey:key] valueForKey:@"newCommentsCount"] intValue];
    self.blockNoLabel.text = blockNo;
    
    self.streetLabel.text = streetName;
    
    self.unlockButton.tag = [[dict valueForKey:@"block_id"] intValue];
    [self.unlockButton addTarget:self action:@selector(tappedUnlockButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //comments
    if(latestComment != nil)
    {
        self.lastMsgByLabel.hidden = NO;
        self.lastMsgLabel.hidden = NO;
        self.dateLabel.hidden = NO;
        self.msgCount.hidden = NO;
        
        //comment date
        double timeStamp = [[latestComment valueForKeyPath:@"comment_on"] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
        NSString *dateStringForm = [date stringWithHumanizedTimeDifference:0 withFullString:NO];
        
        self.lastMsgByLabel.text = [NSString stringWithFormat:@"%@:",[latestComment valueForKey:@"comment_by"]];
        self.lastMsgLabel.text = [latestComment valueForKey:@"comment"];
        self.dateLabel.text = dateStringForm;
        
        if(newCommentsCount > 0)
        {
            self.msgCount.hidden = NO;
            self.msgCount.text = [NSString stringWithFormat:@"%d",newCommentsCount];
            self.msgCount.backgroundColor = [UIColor blueColor];
            self.msgCount.hasBorder = YES;
            self.msgCount.textColor = [UIColor whiteColor];
        }
        else
            self.msgCount.hidden = YES;
    }
    else
    {
        self.lastMsgByLabel.hidden = YES;
        self.lastMsgLabel.hidden = YES;
        self.dateLabel.hidden = YES;
        self.msgCount.hidden = YES;
    }
}


- (IBAction)tappedUnlockButton:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInteger:btn.tag];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedUnlockButton" object:nil userInfo:@{@"scheduleId":tag}];
}

@end
