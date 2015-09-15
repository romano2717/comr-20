//
//  MessageData.h
//  comress
//
//  Created by Diffy Romano on 10/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"
#import "Users.h"

@interface MessageData : NSObject

{
    Users *users;
}

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

- (void)addPhotoMediaMessageWithImage:(UIImage *)image SenderId:(NSString *)senderId DisplayName:(NSString *)displayName;

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;
- (void)addLocationMediaWithLocation:(CLLocation *)location withCompletion:(JSQLocationMediaItemCompletionBlock)completion;

- (void)addVideoMediaMessage;


@end
