//
//  SubCheckListTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 28/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SubCheckListTableViewCell.h"

@implementation SubCheckListTableViewCell

@synthesize checkBoxBtn, checkListLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    checkBoxBtn.tag = [[dict valueForKey:@"w_chklistid"] intValue];
    checkListLabel.text = [dict valueForKey:@"w_item"];
}

@end
