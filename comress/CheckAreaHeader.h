//
//  CheckAreaHeader.h
//  comress
//
//  Created by Diffy Romano on 27/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckAreaHeader : UITableViewCell


@property (nonatomic, weak) IBOutlet UIButton *checkBoxBtn;
@property (nonatomic, weak) IBOutlet UILabel *checkListLabel;
@property (nonatomic, weak) IBOutlet UILabel *scheduleDate;
@property (nonatomic, weak) IBOutlet UIButton *saveBtn;
@property (nonatomic, weak) IBOutlet UIButton *finishBtn;
@property (nonatomic, weak) IBOutlet UILabel *scheduleFinishedLabel;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
