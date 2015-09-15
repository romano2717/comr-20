//
//  SurveyTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyTableViewCell.h"

@implementation SurveyTableViewCell

@synthesize numOfQuestions;

- (void)awakeFromNib {
    // Initialization code
    
    questions = [[Questions alloc] init];
    
    numOfQuestions = (int)[[questions questions] count];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict forSegment:(NSNumber *)segment
{
    @try {

        NSDictionary *survey = [dict objectForKey:@"survey"];
        NSDictionary *address = [dict objectForKey:@"address"];
        BOOL overdue = [[dict valueForKey:@"overdue"] boolValue];
        BOOL aboutToBeOverdue = NO;
        
        
        //set labels as empty so we always reset and avoid cell re-use problem
        self.dateLabel.text = @"";
        self.residentName.text = @"";
        self.satisfactionRatingLabel.text = @"";
        self.addressLabel.text = @"";
        self.arrowImageView.image = nil;
        
        if(survey != nil)
        {
            if([survey valueForKey:@"resident_name"] != [NSNull null])
                self.residentName.text = [survey valueForKey:@"resident_name"];
            
            double timeStamp = [[survey valueForKey:@"survey_date"] doubleValue];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"dd-MMM-YYYY h:mm"];
            NSString *datestring = [format stringFromDate:date];
            
            self.dateLabel.text = [NSString stringWithFormat:@"%@",datestring];
            
            self.satisfactionRatingLabel.text = [NSString stringWithFormat:@"%.2f%% Satisfaction",[[survey valueForKey:@"average_rating"] floatValue]];
            
            if([segment longValue] == 0)
            {
                NSDate *now = [NSDate date];
                int diff = [self daysBetween:date and:now];
                
                if(diff >= 2)
                    aboutToBeOverdue = YES;
            }
        }
        
        if(address != nil)
        {
            if([survey valueForKey:@"address"] != [NSNull null])
            {
#if DEBUG
                if([survey valueForKey:@"survey_id"] != [NSNull null])
                    self.addressLabel.text = [NSString stringWithFormat:@"%d:%@",[[survey valueForKey:@"survey_id"] intValue],[address valueForKey:@"address"]];
                else
                    self.addressLabel.text = [NSString stringWithFormat:@"%d:%@",0,[address valueForKey:@"address"]];
#else
                self.addressLabel.text = [address valueForKey:@"address"];
#endif
                
            }
            
        }
        
        if([segment intValue] == 0)
        {
            if(aboutToBeOverdue && overdue)
            {
                self.residentName.textColor = [UIColor redColor];
                self.dateLabel.textColor = [UIColor redColor];
                self.satisfactionRatingLabel.textColor = [UIColor redColor];
                self.addressLabel.textColor = [UIColor redColor];
            }
            else
            {
                self.residentName.textColor = [UIColor blackColor];
                self.dateLabel.textColor = [UIColor blackColor];
                self.satisfactionRatingLabel.textColor = [UIColor blackColor];
                self.addressLabel.textColor = [UIColor blackColor];
            }
        }
        else
        {
            self.residentName.textColor = [UIColor blackColor];
            self.dateLabel.textColor = [UIColor blackColor];
            self.satisfactionRatingLabel.textColor = [UIColor blackColor];
            self.addressLabel.textColor = [UIColor blackColor];
        }
        
        
        //check if survey is unfinished
        int surveyId = [[survey valueForKey:@"survey_id"] intValue];
        int status = [[survey valueForKey:@"status"] intValue];
        
        if(surveyId == 0 && status == 0)
        {
            self.arrowImageView.image = [UIImage imageNamed:@"partial.png"];
        }
        else
        {
            self.arrowImageView.image = [UIImage imageNamed:@"arrow.png"];
        }
        
        if([dict valueForKey:@"issuesCount"] != [NSNull null])
        {
            if([[dict valueForKey:@"issuesCount"] intValue] > 0)
                self.numberOfIssuesLabel.text = [NSString stringWithFormat:@"No. of issues: %d",[[dict valueForKey:@"issuesCount"] intValue]];
            else
                self.numberOfIssuesLabel.text = @"";
        }
        
        //temp
        self.numberOfIssuesLabel.hidden = YES;
        
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"NSException %@",exception);
    }
    @finally {

    }
}

- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return (int)[components day]+1;
}

@end
