//
//  RoutineTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "NSDate+HumanizedTime.h"
#import "BadgeLabel.h"

@interface RoutineTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *blockNoLabel;
@property (nonatomic, weak) IBOutlet UILabel *streetLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastMsgByLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastMsgLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UIButton *unlockButton;
@property (nonatomic, weak) IBOutlet BadgeLabel *msgCount;

- (void)initCellWithResultSet:(NSDictionary *)dict postDict:(NSDictionary *)postDict;

@end
