//
//  Device_token.h
//  comress
//
//  Created by Diffy Romano on 13/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Device_token : NSObject
{
    Database *myDatabase;
}
@property (nonatomic, strong) NSString *device_token;

@end
