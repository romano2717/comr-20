//
//  SubCheckListTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 28/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubCheckListTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkListLabel;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
