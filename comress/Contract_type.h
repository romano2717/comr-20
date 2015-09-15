//
//  Contrac_type.h
//  comress
//
//  Created by Diffy Romano on 27/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Contract_type : NSObject
{
    Database *myDatabase;
}

- (NSArray *)contractTypes;

- (NSString *)contractDescriptionForId:(NSNumber *)theId;

@end
