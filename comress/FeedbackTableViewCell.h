//
//  FeedbackTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"

@interface FeedbackTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedbackLabel;
@property (nonatomic, weak) IBOutlet UIButton *conservancyChatBtn;
@property (nonatomic, weak) IBOutlet UIButton *hortChatBtn;
@property (nonatomic, weak) IBOutlet UIButton *pumpChatBtn;
@property (nonatomic, weak) IBOutlet UIButton *mosqChatBtn;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
