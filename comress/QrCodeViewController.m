//
//  QrCodeViewController.m
//  comress
//
//  Created by Diffy Romano on 11/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "QrCodeViewController.h"

@interface QrCodeViewController ()



@end

@implementation QrCodeViewController

@synthesize laserView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    laserView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.previewView.frame.size.width, 2)];
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
    
    [self toggleScanningTapped:self];
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
        laserView.backgroundColor = [UIColor redColor];
        laserView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        laserView.layer.shadowOpacity = 0.6;
        laserView.layer.shadowRadius = 1.5;
        laserView.alpha = 1.0;
        
        if (![[self.previewView subviews] containsObject:laserView])
        {
            DDLogVerbose(@"add");
            [self.previewView addSubview:laserView];
        }
        
        [UIView animateWithDuration:1.0 delay:0.0 options: UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
            laserView.frame = CGRectMake(0, self.previewView.frame.size.height, self.previewView.frame.size.width, 2);
        } completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (AVMetadataMachineReadableCodeObject *code in codes) {

                [self.laserView removeFromSuperview];
                
                self.result.text = code.stringValue;
                
                [self stopScanning];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                        NSDictionary *dict;
                        
                        if(self.location != nil)
                            dict = @{@"scanValue":code.stringValue,@"location":self.location};
                        else
                            dict = @{@"scanValue":code.stringValue,@"location":[NSNull null]};
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"waitingForLocation" object:dict userInfo:dict];
                    }];
                });
            }
        });
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
        
        NSDictionary *dict;
        
        if(self.scanValue != nil)
            dict = @{@"scanValue":self.scanValue,@"location":self.location};
        else
            dict = @{@"location":self.location,@"scanValue":[NSNull null]};
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"locatingComplete" object:nil userInfo:dict];
        [locationManager stopUpdatingLocation];
    }
}

@end
