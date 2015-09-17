//
//  IssuesTableViewCell.h
//  comress
//
//  Created by Diffy Romano on 5/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "NSDate+HumanizedTime.h"
#import "UIImageView+WebCache.h"
#import "BadgeLabel.h"
#import "Post.h"


@interface IssuesTableViewCell : UITableViewCell
{
    Post *post;
}
@property (nonatomic, weak) IBOutlet UIImageView *mainImageView;
@property (nonatomic, weak) IBOutlet UIImageView *pinImageView;
@property (nonatomic, weak) IBOutlet UIImageView *aNewPostImageView;
@property (nonatomic, weak) IBOutlet BadgeLabel *commentsCount;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusProgressView;
@property (nonatomic, weak) IBOutlet UILabel *postTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastMessagByLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastMessageLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *messageCountLabel;

@property (nonatomic, strong) NSArray *actionListArray;
@property (nonatomic, strong) NSArray *actionListValArray;

- (void)initCellWithResultSet:(NSDictionary *)dict forSegment:(long)segment;

@end
