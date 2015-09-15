//
//  Check_area.h
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"


@interface Check_area : NSObject
{
    Database *myDatabase;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

- (NSArray *)scheduleForBlock:(NSNumber *)blockId;

- (NSArray *)checkAreaForJobTypeId:(NSNumber *)jobTypeId;

- (NSArray *)checkListForJobTypeId:(NSNumber *)jobTypeId;

- (NSDictionary *)checkAreaForId:(NSNumber *)checkAreaId;
@end
