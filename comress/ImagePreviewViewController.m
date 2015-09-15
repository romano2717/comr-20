//
//  ImagePreviewViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ImagePreviewViewController.h"

@interface ImagePreviewViewController ()

@end

@implementation ImagePreviewViewController

@synthesize image;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImage *i = image;
    self.imageView.image = i;
    
    CGFloat ratio = CGRectGetWidth(self.scrollView.bounds) / image.size.width;
    self.imageView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), image.size.height * ratio);
    self.imageView.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds));
    self.imageView.image = image;
    self.scrollView.clipsToBounds = YES;
    self.scrollView.contentSize = self.imageView.bounds.size;
    self.scrollView.zoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.minimumZoomScale = 1.0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIView *subView = self.imageView;
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
