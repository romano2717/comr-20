//
//  Client.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Client : NSObject
{
    Database *myDatabase;
}

@property (nonatomic, strong) NSDictionary *clientDictionary;


@end
