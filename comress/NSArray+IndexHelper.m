//
//  NSArray+IndexHelper.m
//  comress
//
//  Created by Diffy Romano on 30/6/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "NSArray+IndexHelper.h"

@implementation NSArray (IndexHelper)
-(id) safeObjectAtIndex:(NSUInteger)index {
    if (index>=self.count) {
        return nil;
    }
    return [self objectAtIndex:index];
}
@end
