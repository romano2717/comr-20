//
//  QRCodeScanningViewController.m
//  comress
//
//  Created by Diffy Romano on 4/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "QRCodeScanningViewController.h"

@interface QRCodeScanningViewController ()

@end

@implementation QRCodeScanningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //init location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = 100;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    //ask permission to use location service
    [locationManager requestAlwaysAuthorization];
    [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopScanning];
}

- (IBAction)canceScanning:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - Scanner

- (MTBBarcodeScanner *)scanner {
    if (!_scanner) {
        _scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    }
    return _scanner;
}

#pragma mark - Scanning

- (void)startScanning {
    [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        for (AVMetadataMachineReadableCodeObject *code in codes) {
            _scanValue = code.stringValue;
            [self scanningAndLocationTraceComplete];
        }
    }];
}

- (void)stopScanning {
    [self.scanner stopScanning];
}

#pragma mark - Actions

- (IBAction)toggleScanningTapped:(id)sender {
    
    if ([self.scanner isScanning]) {
        [self stopScanning];
    } else {
        [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
            if (success) {
                [self startScanning];
            } else {
                [self displayPermissionMissingAlert];
            }
        }];
    }
}

- (IBAction)traceLocation:(id)sender
{
    [MBProgressHUD showHUDAddedTo:_previewView animated:YES];
    
    [locationManager stopUpdatingLocation];
    [locationManager startUpdatingLocation];
}

- (void)displayPermissionMissingAlert {
    NSString *message = nil;
    if ([MTBBarcodeScanner scanningIsProhibited]) {
        message = @"This app does not have permission to use the camera.";
    } else if (![MTBBarcodeScanner cameraIsPresent]) {
        message = @"This device does not have a camera.";
    } else {
        message = @"An unknown error occurred.";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Scanning Unavailable"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    
    BOOL locationIsGood = YES;
    
    if (locationAge > 15.0)
    {
        locationIsGood = NO;
    }
    
    if (loc.horizontalAccuracy < 0)
    {
        locationIsGood = NO;
    }
    
    if(locationIsGood)
    {
        self.location = loc;
        
        [self scanningAndLocationTraceComplete];
        
        [locationManager stopUpdatingLocation];
        
        [MBProgressHUD hideAllHUDsForView:_previewView animated:YES];
    }
}


- (void)scanningAndLocationTraceComplete
{
    if(_scanValue != nil && _scanValue.length != 0)
    {
        [self stopScanning];
        
        [self.view viewWithTag:100].hidden = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didScanQrCodePerBlock" object:nil userInfo:@{@"scanValue":_scanValue,@"location":_location,@"scheduleDict":_scheduleDetailDict}];
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }
}

@end
