//
//  Contrac_type.m
//  comress
//
//  Created by Diffy Romano on 27/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Contract_type.h"

@implementation Contract_type

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    return self;
}

- (NSArray *)contractTypes
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from contract_type"];
        
        while ([rs next]) {
            [arr addObject:[rs resultDictionary]];
        }
    }];
    
    return arr;
}

- (NSString *)contractDescriptionForId:(NSNumber *)theId
{
    __block NSString *contract;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from contract_type_public where id = ?",theId];
        
        while ([rs next]) {
            contract = [rs stringForColumn:@"contract"];
        }
    }];
    
    return contract;
}
@end
