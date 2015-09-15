//
//  QuestionsTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "QuestionsTableViewCell.h"

@implementation QuestionsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    self.questionLabel.text = [dict valueForKey:@"en"];
    
    int rating = [[dict valueForKey:@"rating"] intValue];
    
    if(rating <= 3)
        self.ratingImageView.image = [UIImage imageNamed:@"excellent@2x"];
    if(rating <= 2)
        self.ratingImageView.image = [UIImage imageNamed:@"aver@2x"];
    if(rating <= 1)
        self.ratingImageView.image = [UIImage imageNamed:@"poor@2x"];
}

@end
