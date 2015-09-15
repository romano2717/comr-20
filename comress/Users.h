//
//  Users.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"


@interface Users : NSObject
{
    Database *myDatabase;
}

@property (nonatomic, strong) NSNumber *client_id;
@property (nonatomic, strong) NSString *full_name;
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *device_token;
@property (nonatomic, strong) NSString *company_id;
@property (nonatomic, strong) NSString *user_id;
@property (nonatomic, strong) NSString *company_name;
@property (nonatomic, strong) NSNumber *group_id;
@property (nonatomic, strong) NSString *group_name;
@property (nonatomic, strong) NSNumber *device_id;



@end
