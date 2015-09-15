//
//  ImagePreviewViewController.h
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePreviewViewController : UIViewController<UIScrollViewDelegate>
{

}

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@end
