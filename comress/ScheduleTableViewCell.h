//
//  ScheduleTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScheduleTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *beforeLabel;
@property (nonatomic, weak) IBOutlet UILabel *afterLabel;

@property (nonatomic, weak) IBOutlet UIButton *beforeImageBtn;
@property (nonatomic, weak) IBOutlet UIButton *afterImageBtn;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
