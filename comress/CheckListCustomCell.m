//
//  CheckListCustomCell.m
//  comress
//
//  Created by Diffy Romano on 16/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListCustomCell.h"

@implementation CheckListCustomCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    NSDictionary *checkList = [dict objectForKey:@"checkListArray"];
    NSArray *checkedCheckList = [dict objectForKey:@"checked"];
    NSIndexPath *indexPath = [dict objectForKey:@"indexPath"];
    BOOL checkListWasModified = [[dict valueForKey:@"checkListWasModified"] boolValue];
    
    DDLogVerbose(@"checked %@",checkedCheckList);
    
    NSString *checkListName = [checkList valueForKey:@"CheckListName"];
    
    BOOL isChecked = [[checkList valueForKey:@"IsCheck"] boolValue];
    
    
    //defaults
    [_checkBoxBtn setSelected:NO];
    
    
    //config ui
    _checkListLabel.text = checkListName;
    
    [_checkBoxBtn setSelected:isChecked];
    _checkBoxBtn.tag = indexPath.row;
    
    //check if this row is manually selected
    if([checkedCheckList containsObject:[NSNumber numberWithInt:(int)indexPath.row]])
        [_checkBoxBtn setSelected:YES];
    else if([checkedCheckList containsObject:[NSNumber numberWithInt:(int)indexPath.row]] == NO && checkListWasModified == YES) //list was modified
    {
        if([checkedCheckList containsObject:[NSNumber numberWithInt:(int)indexPath.row]] == NO)
            [_checkBoxBtn setSelected:NO];
    }
}
@end
