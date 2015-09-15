//
//  SurveyViewController.h
//  comress
//
//  Created by Diffy Romano on 1/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "Questions.h"
#import "ResidentInfoViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FeedBackViewController.h"

@interface SurveyViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,CLLocationManagerDelegate>
{
    Database *myDatabase;
    Questions *questions;
    
    CLLocationManager *locationManager;
}
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, weak) IBOutlet UICollectionView *ratingsCollectionView;
@property (nonatomic, weak) IBOutlet UILabel *questionCounter;
@property (nonatomic, weak) IBOutlet UITextView *questionTextView;

@property (nonatomic, strong) NSArray *ratingsImageArray;
@property (nonatomic, strong) NSArray *ratingsImageSelectedArray;
@property (nonatomic, strong) NSArray *ratingsStringArray;
@property (nonatomic, strong) NSArray *surveyQuestions;

@property (nonatomic) int selectedRating;
@property (nonatomic) int currentQuestionIndex;
@property (nonatomic) long long currentSurveyId;

@property (nonatomic, strong)CLLocation *currentLocation;

@property (nonatomic) int averageRating;

@property (nonatomic, strong) NSString *locale;

@property (nonatomic, strong) CLPlacemark *placemark;

@property (nonatomic, strong) NSArray *placesArray;

@property (nonatomic, strong) NSMutableArray *foundPlacesFinalArray;

@property (nonatomic) BOOL currentLocationFound;

@property (nonatomic, strong) NSMutableArray *closeAreas;

@property (nonatomic) int numberOfQuestionsAnswered;


//resume survey
@property (nonatomic) int clientSurveyIdIncompleteSurvey;
@property (nonatomic) int resumeSurveyAtQuestionIndex;

@end
