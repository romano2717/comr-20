//
//  Check_list.h
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Check_list : NSObject

{
    Database *myDatabase;
}


- (NSArray *)fetchCheckListForBlockId:(NSNumber *)blkId;

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

- (NSArray *)checklistForJobTypeId:(NSNumber *)jobTypeId;

- (NSArray *)checkAreaForJobTypeId:(NSNumber *)jobTypeId;

- (NSArray *)updatedChecklist;

- (NSArray *)inspectionResultCheckListForStatus:(NSNumber *)status;

- (NSArray *)checkListForCheckAreaId:(NSNumber *)checkAreaId JobTypeId:(NSNumber *)jobTypeId;

- (NSArray *)checkListForCheckAreaId:(NSNumber *)checkAreaId;
@end
