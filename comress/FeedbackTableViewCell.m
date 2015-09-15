//
//  FeedbackTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedbackTableViewCell.h"

@implementation FeedbackTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    NSDictionary *address = [dict objectForKey:@"address"];
    NSDictionary *feedBack = [dict objectForKey:@"feedback"];
    
    self.addressLabel.text = [address valueForKey:@"address"];
    self.feedbackLabel.text = [feedBack valueForKey:@"description"];

    
    //post details
//    post =     (
//                {
//                    address = "BLK24 Tanglin Halt Road";
//                    "block_id" = 141;
//                    "client_post_id" = 502;
//                    "contract_type" = 1;
//                    isUpdated = 1;
//                    level = najan;
//                    "post_by" = combdiffy1;
//                    "post_date" = "1428395575.696388";
//                    "post_id" = 441;
//                    "post_topic" = "multi post";
//                    "post_type" = 1;
//                    "postal_code" = 140024;
//                    seen = 1;
//                    severity = 2;
//                    status = 0;
//                    statusWasUpdated = 0;
//                    "updated_on" = "1428395575.696388";
//                },
//                {
//                    address = "BLK24 Tanglin Halt Road";
//                    "block_id" = 141;
//                    "client_post_id" = 503;
//                    "contract_type" = 2;
//                    isUpdated = 1;
//                    level = najan;
//                    "post_by" = combdiffy1;
//                    "post_date" = "1428395582.346041";
//                    "post_id" = 442;
//                    "post_topic" = "multi post";
//                    "post_type" = 1;
//                    "postal_code" = 140024;
//                    seen = 1;
//                    severity = 2;
//                    status = 0;
//                    statusWasUpdated = 0;
//                    "updated_on" = "1428395582.346041";
//                }
//                );
    
    NSArray *posts = [dict objectForKey:@"post"];
    NSArray *contactTypesArr = [dict objectForKey:@"contractTypes"];
    for (int i = 0; i < posts.count; i ++) {
        
        NSDictionary *postDict = [posts objectAtIndex:i];
        NSNumber *contractType = [NSNumber  numberWithInt:[[postDict valueForKey:@"contract_type"] intValue]];
        
        
        for (int x = 0; x < contactTypesArr.count; x++) {
            NSDictionary *dict = [contactTypesArr objectAtIndex:x];
            
            NSNumber *theId = [NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]];
            NSString *theContract = [dict valueForKey:@"contract"];
            
            if(theId == contractType)
            {
                if([theContract isEqualToString:@"Conservancy"])
                {
                    //self.conservancyChatBtn
                    
                }
                
                else if ([theContract isEqualToString:@"Horticulture"])
                {
                    //self.hortChatBtn
                }
                
                else if ([theContract isEqualToString:@"Pump"])
                {
                    //self.pumpChatBtn
                }
                else
                {
                    //self.mosqChatBtn
                }
            }
        }
    }
}

@end
