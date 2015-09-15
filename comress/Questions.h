//
//  Questions.h
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"


@interface Questions : NSObject
{
    Database *myDatabase;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

- (NSArray *)questions;


@end
