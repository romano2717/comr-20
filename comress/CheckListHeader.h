//
//  CheckListHeader.h
//  comress
//
//  Created by Diffy Romano on 20/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"

@interface CheckListHeader : UITableViewCell
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkListLabel;
@property (nonatomic, weak) IBOutlet UILabel *scheduleDate;
@property (nonatomic, weak) IBOutlet UIButton *saveBtn;
@property (nonatomic, weak) IBOutlet UIButton *finishBtn;
@property (nonatomic, weak) IBOutlet UILabel *scheduleFinishedLabel;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
