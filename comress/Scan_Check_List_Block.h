//
//  Scan_Check_List_Block.h
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Scan_Check_List_Block : NSObject
{
    Database *myDatabase;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;
@end
