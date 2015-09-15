//
//  QRCodeScanningViewController.h
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTBBarcodeScanner.h"
#import "AppWideImports.h"
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"

@interface QRCodeScanningViewController : UIViewController<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *scanValue;
@property (nonatomic, strong) MTBBarcodeScanner *scanner;
@property (nonatomic, weak) IBOutlet UIView *previewView;


@property (nonatomic, strong) NSDictionary *scheduleDetailDict;

@end
