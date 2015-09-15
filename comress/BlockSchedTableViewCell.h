//
//  BlockSchedTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 3/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlockSchedTableViewCell : UITableViewCell

{

}

@property (nonatomic, weak) IBOutlet UILabel *blockNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *blocNotificationLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberOfJobsLabel;
@property (nonatomic, weak) IBOutlet UIButton *unlockBlockButton;

@property (nonatomic, strong)NSDateFormatter *formatter;
- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
