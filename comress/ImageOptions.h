//
//  ImageOptions.h
//  comress
//
//  Created by Diffy Romano on 20/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ImageOptions : UIImage

- (void)resizeImageAtPath:(NSString *)imagePath;
- (UIImage *)resizeImageAsThumbnailForImage:(UIImage *)image;
- (NSString *)saveImageToDocsDir:(UIImage *)image;
@end
