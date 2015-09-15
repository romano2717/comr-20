//
//  NavigationBarTitleWithSubtitleView.m
//  comress
//
//  Created by Diffy Romano on 6/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "NavigationBarTitleWithSubtitleView.h"

@interface NavigationBarTitleWithSubtitleView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;

@end

@implementation NavigationBarTitleWithSubtitleView

@synthesize titleLabel;
@synthesize detailLabel;

- (id) init
{
    self = [super initWithFrame:CGRectMake(0, 0, 200, 44)];
    if (self) {
        [self setBackgroundColor: [UIColor clearColor]];
        [self setAutoresizesSubviews:YES];
        
        CGRect titleFrame = CGRectMake(0, 2, 200, 24);
        titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:20];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor blueColor];
        titleLabel.shadowOffset = CGSizeMake(0, -1);
        titleLabel.text = @"";
        [self addSubview:titleLabel];
        
        CGRect detailFrame = CGRectMake(0, 24, 200, 44-24);
        detailLabel = [[UILabel alloc] initWithFrame:detailFrame];
        detailLabel.backgroundColor = [UIColor clearColor];
        detailLabel.font = [UIFont systemFontOfSize:12.0f];
        detailLabel.textAlignment = NSTextAlignmentCenter;
        detailLabel.textColor = [UIColor grayColor];
        detailLabel.shadowOffset = CGSizeMake(0, -1);
        detailLabel.text = @"";
        detailLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:detailLabel];
        
        [self setAutoresizingMask : (UIViewAutoresizingFlexibleLeftMargin |
                                     UIViewAutoresizingFlexibleRightMargin |
                                     UIViewAutoresizingFlexibleTopMargin |
                                     UIViewAutoresizingFlexibleBottomMargin)];
    }
    return self;
}

- (void) setTitleText: (NSString *) aTitleText
{
    [self.titleLabel setText:aTitleText];
}

- (void) setDetailText: (NSString *) aDetailText
{  
    [self.detailLabel setText:aDetailText];  
}  

@end
