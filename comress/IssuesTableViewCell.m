//
//  IssuesTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 5/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesTableViewCell.h"

@implementation IssuesTableViewCell

@synthesize mainImageView,statusLabel,statusProgressView,postTitleLabel,addressLabel,lastMessagByLabel,lastMessageLabel,dateLabel,messageCountLabel,pinImageView,commentsCount,aNewPostImageView;

@synthesize actionListArray,actionListValArray;


- (void)awakeFromNib {
    // Initialization code
    
    post = [[Post alloc] init];
    
    NSArray *actionListTemp = [post getAvailableActions];
    actionListArray = [actionListTemp valueForKey:@"ActionName"];
    actionListValArray = [actionListTemp  valueForKey:@"ActionValue"];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)initCellWithResultSet:(NSDictionary *)dict forSegment:(long)segment
{
    @try {
        NSDictionary *topDict = (NSDictionary *)[[dict allValues] firstObject];
        NSDictionary *postDict = [topDict valueForKey:@"post"];
        NSArray *postComments = [topDict valueForKey:@"postComments"];
        NSArray *postImages = [topDict valueForKey:@"postImages"];
#if DEBUG
        NSString *postTopic = @"";
        
        NSString *seenTag = [[postDict valueForKey:@"seen"] boolValue] ? @"" : @"!";
        
        if([postDict valueForKey:@"post_id"] == [NSNull null])
            postTopic = [NSString stringWithFormat:@"%d%@:%@",0,seenTag,[postDict valueForKey:@"post_topic"]];
        else
            postTopic = [NSString stringWithFormat:@"%d%@:%@",[[postDict valueForKey:@"post_id"] intValue],seenTag,[postDict valueForKey:@"post_topic"]];
#else
        NSString *postTopic = [postDict valueForKey:@"post_topic"] ? [postDict valueForKey:@"post_topic"] : @"Untitled";
#endif
        
        
        //update on
        double timeStamp = [[postDict valueForKey:@"updated_on"] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
        NSString *dateStringForm = [date stringWithHumanizedTimeDifference:0 withFullString:NO];
        
        //due date
        NSDate *now = [NSDate date];
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*24*60*60]; //add 3 days
        
        if([postDict valueForKey:@"dueDate"] != [NSNull null])
        {
            double timeStamp2 = [[postDict valueForKeyPath:@"dueDate"] doubleValue];
            dueDate = [NSDate dateWithTimeIntervalSince1970:timeStamp2];
        }
        
        
        //post main image
        NSDictionary *imageDict = (NSDictionary *)[postImages firstObject];
        NSString *imagePath = [imageDict valueForKey:@"image_path"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        
        //last message & last message by
        //by default, last post is by OP until last commenter
        NSString *lastMsgBy = [postDict valueForKey:@"post_by"];
        NSString *lastMsg = @"";
        
        //read status
        int newCommentsCounter = [[topDict valueForKey:@"newCommentsCount"] intValue];
        
        int severity = [[postDict valueForKey:@"severity"] intValue];
        
        NSDictionary *lastCommentDict = [postComments lastObject];
        
        if (postComments.count > 0) {
            
            lastMsgBy = [lastCommentDict valueForKey:@"comment_by"];
            lastMsg = [lastCommentDict valueForKey:@"comment"];
        }
        
        //status
        int status = [[postDict valueForKey:@"status"] intValue] ? [[postDict valueForKey:@"status"] intValue] : 0;
        CGFloat progress = 0.0; //Pending
        NSString *statusString = [[post getActionDescriptionForStatus:status] valueForKey:@"name"];
        
        switch (status) {
                
            case 1:
            {
                progress = 0.5;
                break;
            }
                
            case 2:
            {
                progress = 0.2;
                break;
            }
                
            case 3:
            {
                progress = 1.0;
                break;
            }
                
            case 4:
            {
                progress = 0;
                break;
            }
            
            case 5:
            {
                progress = 0.5;
                break;
            }
                
            default:
            {
                progress = 0.2;
                break;
            }
                
        }
        
        //default colors & ui
        postTitleLabel.textColor = [UIColor blackColor];
        addressLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
        lastMessagByLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
        lastMessageLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
        statusProgressView.tintColor = [UIColor redColor];
        
        
        //set ui
        [mainImageView sd_setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"noImage2@2x"] options:SDWebImageProgressiveDownload];
        statusLabel.text = statusString;
        
        statusProgressView.progress = progress;
        
        if(progress == 1.0)
            statusProgressView.tintColor = [UIColor greenColor];
        
        postTitleLabel.text = postTopic;
        addressLabel.text = [postDict valueForKey:@"address"] ? [postDict valueForKey:@"address"] : @"Address:";
        lastMessagByLabel.text = lastMsgBy;
        lastMessageLabel.text = lastMsg;
        dateLabel.text = dateStringForm ? dateStringForm : @"-";
        messageCountLabel.text = @"";
        
        if(severity == 2)//Routine
            pinImageView.hidden = YES;
        

        if(newCommentsCounter > 0)
        {
            commentsCount.hidden = NO;
            commentsCount.text = [NSString stringWithFormat:@"%d",newCommentsCounter];
            commentsCount.backgroundColor = [UIColor blueColor];
            commentsCount.hasBorder = YES;
            commentsCount.textColor = [UIColor whiteColor];
            
        }
        else
            commentsCount.hidden = YES;
        
        
        if(segment == 0) //check if the issue is 1 day before the overdue
        {
            NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
            NSDate *now = [[NSCalendar currentCalendar] dateFromComponents:comps];
            
            int diff = [self daysBetween:now and:dueDate];
            
            if(diff == 1 && status != 4)
            {
                postTitleLabel.textColor = [UIColor redColor];
                addressLabel.textColor = [UIColor redColor];
                lastMessagByLabel.textColor = [UIColor redColor];
                lastMessageLabel.textColor = [UIColor redColor];
                
            }
            else
            {
                postTitleLabel.textColor = [UIColor blackColor];
                addressLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
                lastMessagByLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
                lastMessageLabel.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102/255.0 alpha:1.0f];
            }
        }
        
        aNewPostImageView.hidden = YES;
        aNewPostImageView.hidden = [[postDict valueForKey:@"seen"] boolValue];
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"ek ek ek %@",exception);
    }
    @finally {
 
    }
}

- (UILabel *)deepLabelCopy:(UILabel *)label {
    UILabel *duplicateLabel = [[UILabel alloc] initWithFrame:label.frame];
    duplicateLabel.text = label.text;
    duplicateLabel.textColor = label.textColor;
    return duplicateLabel;
}

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return (int)[components day]+1;
}


@end
