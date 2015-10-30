//
//  ViewController.h
//  WasonSpeechQA
//
//  Created by Andrew Trice on 6/15/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ResultsTableViewController.h"
#import "IMFCore/IMFLogger.h"
#import "IMFCore/IMFResourceRequest.h"
#import "IMFURLProtocol/IMFURLProtocol.h"
#import <watsonsdk/SpeechToText.h>
#import <watsonsdk/STTConfiguration.h>
#import <watsonsdk/TextToSpeech.h>
#import <watsonsdk/TTSConfiguration.h>

#define MAX_DB 65.0f
#define SILENCE_DB 38.0f
#define SILENCE_DURATION 3.0f


@interface ViewController : UIViewController {
    
    IMFLogger *logger;
    NSString *transcribeURL;
    NSString *askURL;
    NSString *transcript;
}


@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UILabel *queryLabel;
@property (nonatomic, weak) IBOutlet UIView *meterView;

@property (nonatomic, strong) NSArray *searchData;
@property (nonatomic, strong) SpeechToText *stt;


- (IBAction)recordButtonPressed:(id)sender;

-(IBAction) startRecording;
-(IBAction) stopRecording;

@end

