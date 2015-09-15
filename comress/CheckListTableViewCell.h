//
//  CheckListTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"

@interface CheckListTableViewCell : UITableViewCell

- (void)initCellWithResultSet:(NSDictionary *)dict;

@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkList;
@end
