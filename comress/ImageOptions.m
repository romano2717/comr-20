//
//  ImageOptions.m
//  comress
//
//  Created by Diffy Romano on 20/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ImageOptions.h"

@implementation ImageOptions

- (void)resizeImageAtPath:(NSString *)imagePath {
    // Create the image source
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath:imagePath], NULL);
    // Create thumbnail options
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(640)
                                                           };
    // Generate the thumbnail
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options); 
    CFRelease(src);
    // Write the thumbnail at path
    [self CGImageWriteToFile:thumbnail Path:imagePath];
}


- (void) CGImageWriteToFile:(CGImageRef)image Path:(NSString *) path {
    CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
}

- (UIImage *)resizeImageAsThumbnailForImage:(UIImage *)image
{
    UIImage *img;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)@{
                                                          (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                          (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                          (id) kCGImageSourceThumbnailMaxPixelSize : @(500)
                                                          };
    
    CGImageRef thumbNail = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
    CFRelease(src);
    
    img = [UIImage imageWithCGImage:thumbNail];
    
    return img;
}

- (NSString *)saveImageToDocsDir:(UIImage *)image
{
    NSString *path;
    
    return path;
}


@end
