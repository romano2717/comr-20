//
//  Database.h
//  ;;
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "AppWideImports.h"
#import "ApiCallUrl.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPSessionManager.h"
#import <UIKit/UIKit.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface Database : NSObject
{

}

@property (nonatomic, strong) FMDatabaseQueue *databaseQ;
@property (nonatomic, strong) AFHTTPRequestOperationManager *AfManager;
@property (nonatomic, strong) NSString *api_url;
@property (nonatomic, strong) NSString *domain;

@property (nonatomic) int initializingComplete;
@property (nonatomic) int userBlocksInitComplete;
@property (nonatomic) int userBlocksMappingInitComplete;

@property (nonatomic, strong) NSDictionary *clientDictionary;
@property (nonatomic, strong) NSDictionary *userDictionary;
@property (nonatomic, strong) NSDictionary *deviceTokenDictionary;

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

+ (instancetype)sharedMyDbManager;

- (void)createAfManager;

- (void) copyDbToDocumentsDir;

- (void) migrateDatabase;

- (void) alertMessageWithMessage:(NSString *)message;

- (NSString *)dbPath;

- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString;

- (void)notifyLocallyWithMessage:(NSString *)message;

- (NSString *)toJsonString:(id)obj;

- (void)createUser;

- (void)createDeviceToken;

- (void)createClient;

- (void)saveImageToComressAlbum:(UIImage *)image;

- (BOOL)setInitTo:(int)flag;

- (void)setUiAppearanceTextSize:(CGFloat)size;

- (NSString *)createWcfDateWithNsDate: (NSDate *)date;

@end
