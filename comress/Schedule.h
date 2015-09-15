//
//  Schedule.h
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Schedule : NSObject
{
    Database *myDatabase;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

- (NSArray *)fetchScheduleForMe;

- (NSArray *)fetchScheduleForOthersAtPage:(NSNumber *)row;
- (NSArray *)fetchScheduleForOthersAtPage2:(NSNumber *)limit;
- (NSArray *)fetchScheduleForOthersAtPage3:(NSNumber *)limit;

- (NSDictionary *)scheduleForBlockId:(NSNumber *)blockId;

- (BOOL)saveOrFinishScheduleWithId:(NSNumber *)scheduleId checklistId:(NSNumber *)checkListId checkAreaId:(NSNumber *)checkAreaId withStatus:(NSNumber *)status;

- (BOOL)saveOrFinishScheduleWithId2:(NSNumber *)scheduleId checklistId:(NSNumber *)checkListId checkAreaId:(NSNumber *)checkAreaId withStatus:(NSNumber *)status;

- (NSArray *)checkListForScheduleId:(NSNumber *)scheduleId;

@end
