//
//  MessageData.m
//  comress
//
//  Created by Diffy Romano on 10/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "MessageData.h"

@implementation MessageData

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        
        users = [[Users alloc] init];
    }
    
    return self;
}

- (void)addPhotoMediaMessageWithImage:(UIImage *)image SenderId:(NSString *)senderId DisplayName:(NSString *)displayName
{
    
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
    
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:senderId displayName:displayName media:photoItem];

    [self.messages addObject:photoMessage];
    
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    
     CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
     
     JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
     [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
     
     JSQMessage *locationMessage = [JSQMessage messageWithSenderId:users.user_id displayName:users.user_id media:locationItem];
     [self.messages addObject:locationMessage];
    
}

- (void)addLocationMediaWithLocation:(CLLocation *)location withCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:location withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:users.user_id displayName:users.user_id media:locationItem];
    [self.messages addObject:locationMessage];
}

- (void)addVideoMediaMessage
{
    /*
     // don't have a real video, just pretending
     NSURL *videoURL = [NSURL URLWithString:@"file://"];
     
     JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
     JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
     displayName:kJSQDemoAvatarDisplayNameSquires
     media:videoItem];
     [self.messages addObject:videoMessage];
     */
}

@end
