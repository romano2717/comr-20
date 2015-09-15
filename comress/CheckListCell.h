//
//  CheckListCell.h
//  comress
//
//  Created by Diffy Romano on 27/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckListCell : UITableViewCell
- (void)initCellWithResultSet:(NSDictionary *)dict;

@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkList;
@property (nonatomic, weak) IBOutlet UIButton *checkListBtn;
@end
