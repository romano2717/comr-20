//
//  Blocks.h
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Blocks : NSObject
{
    Database *myDatabase;
}
@property (nonatomic, strong) NSNumber *pk_id;
@property (nonatomic, strong) NSNumber *block_id;
@property (nonatomic, strong) NSString *block_no;
@property (nonatomic, strong) NSNumber *is_own_block;
@property (nonatomic, strong) NSString *postal_code;
@property (nonatomic, strong) NSString *street_name;

- (NSArray *)fetchBlocksWithBlockId:(NSNumber *)the_block_id;
- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString forCurrentUser:(BOOL)forCurrentUser;

@end
