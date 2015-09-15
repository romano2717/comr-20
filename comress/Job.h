//
//  Job.h
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Job : NSObject
{
    Database *myDatabase;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;
@end
