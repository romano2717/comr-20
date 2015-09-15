//
//  MessageDataRoutine.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "MessageDataRoutine.h"


@implementation MessageDataRoutine

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
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
    
    
    
}

- (void)addLocationMediaWithLocation:(CLLocation *)location withCompletion:(JSQLocationMediaItemCompletionBlock)completion
{

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

