//
//  QuestionsTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"

@interface QuestionsTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *ratingImageView;
@property (nonatomic, weak) IBOutlet UILabel *questionLabel;

- (void)initCellWithResultSet:(NSDictionary *)dict;

@end
