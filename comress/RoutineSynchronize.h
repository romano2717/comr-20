//
//  RoutineSynchronize.h
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "NSData+Base64.h"

@interface RoutineSynchronize : NSObject
{
    Database *myDatabase;
}

+ (id)sharedRoutineSyncManager;

- (void)startSync;

- (void)stopSync;

- (void)uploadUnlockBlockInfoFromSelf:(BOOL)fromSelf;

- (void)uploadScheduleImageFromSelf:(BOOL)fromSelf;

- (void)uploadScheduleUpdateFromSelf:(BOOL)fromSelf;

- (void)uploadCheckListUpdateFromSelf:(BOOL)fromSelf;

@end
