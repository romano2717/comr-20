//
//  CheckListCustomCell.h
//  comress
//
//  Created by Diffy Romano on 16/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"

@interface CheckListCustomCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkListLabel;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
