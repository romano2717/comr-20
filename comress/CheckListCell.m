//
//  CheckListCell.m
//  comress
//
//  Created by Diffy Romano on 27/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListCell.h"

@implementation CheckListCell

@synthesize checkList,checkBoxBtn,checkListBtn;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    checkList.text = [dict valueForKey:@"w_chkarea"];
    checkBoxBtn.tag = [[dict valueForKey:@"w_chkareaid"] intValue];
    checkListBtn.tag = [[dict valueForKey:@"w_chkareaid"] intValue];
}

@end
