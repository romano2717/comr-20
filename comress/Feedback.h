//
//  Feedback.h
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Feedback : NSObject
{
    Database *myDatabase;
}

- (NSDictionary *)fullFeedbackDetailsForFeedbackClientId:(NSNumber *)feedbackId;
@end
