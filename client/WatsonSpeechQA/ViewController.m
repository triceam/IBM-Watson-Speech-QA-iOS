//
//  ViewController.m
//  WasonSpeechQA
//
//  Created by Andrew Trice on 6/15/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    BOOL recording;
    BOOL shouldShowResults;
}

@end


@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.activityView setColor:[UIColor whiteColor]];
    [self.activityView setHidden:YES];
    
    logger = [IMFLogger loggerForName:@"ViewController"];
    
    NSString *server = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Backend_Route"];
    transcribeURL = [NSString stringWithFormat:@"%@/transcribe", server];
    askURL = [NSString stringWithFormat:@"%@/ask", server];
    
    STTConfiguration *conf = [[STTConfiguration alloc] init];
    [conf setBasicAuthUsername:@"stt username"];
    [conf setBasicAuthPassword:@"stt password"];
    self.stt = [SpeechToText initWithConfig:conf];
    
    recording = NO;
    shouldShowResults = YES;
    self.meterView.hidden = YES;
    
    //set meter levels callback
    [self.stt getPowerLevel:^(float power) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect newFrame = self.meterView.frame;
            
            newFrame.size.width = self.view.frame.size.width;
            newFrame.size.height = self.view.frame.size.height * ((MAX_DB+power)/MAX_DB);
            
            newFrame.origin.x = 0;
            newFrame.origin.y = self.view.frame.size.height - newFrame.size.height;
            [self.meterView setFrame:newFrame];
        });
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordButtonPressed:(id)sender {
    
    if (!recording) {
        [self startRecording];
        [self setMicActiveState];
    } else {
        [self stopRecording];
        [self setMicInactiveState];
    }
}

-(void) setMicActiveState {
    
    [logger logDebugWithMessages:@"setMicActiveState"];
    self.recordButton.selected = YES;
    [self.queryLabel setText:@"What can Watson help you with today?"];
}

-(void) setMicInactiveState {
    
    [logger logDebugWithMessages:@"setMicInactiveState"];
    self.recordButton.selected = NO;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    
}


-(IBAction) startRecording
{
    [logger logDebugWithMessages:@"startRecording"];
    recording = YES;
    self.meterView.hidden = NO;
    transcript = nil;

    [self.stt recognize:^(NSDictionary* res, NSError* err){
        
        if(err == nil) {
            
            transcript = [self.stt getTranscript:res];
            [self.queryLabel setText:transcript];
            
            if([self.stt isFinalTranscript:res]) {
                
                NSLog(@"this is the final transcript");
                
                [self stopRecording];
                [self setMicInactiveState];
                [self requestQA:transcript];
            }
            
        } else {
            recording = NO;

            [self setMicInactiveState];
            if (transcript == nil) {
                [self.queryLabel setText:@"Sorry, I didn't catch that. Try again?"];
                [self.activityView setHidden:YES];
            }
            else
                [self requestQA:transcript];
        }
    }];
    
}

-(IBAction) stopRecording
{
    [logger logDebugWithMessages:@"stopRecording"];
    [self.stt endRecognize];
    recording = NO;
    self.meterView.hidden = YES;
}





-(void) requestQA:(NSString*)query {
    
    [logger logInfoWithMessages:@"Query: %@", query];
    
    NSDictionary *params = @{@"query":query};
    
    IMFResourceRequest * imfRequest = [IMFResourceRequest requestWithPath:askURL method:@"GET" parameters:params];
    [imfRequest sendWithCompletionHandler:^(IMFResponse *response, NSError *error) {
        
    NSDictionary* json = response.responseJson;

    if (json == nil) {
        json = @{@"answers":@[]};
        [logger logErrorWithMessages:@"Unable to retrieve results from server.  %@", [error localizedDescription]];
    }

    [self setSearchData:[json objectForKey:@"answers"]];

    NSString *labelString = nil;

    if ( ![self.searchData count] > 0) {
        labelString = @"Sorry, I was unable find what you are looking for.";
    }

    [logger logInfoWithMessages:@"query complete: %d records", [self.searchData count]];

    //update ui in main thread
    //added shouldShowResults boolean to prevent double triggering of segue when multiple "final" results are returned
    if (shouldShowResults) {
        shouldShowResults = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ( [self.searchData count] > 0) {
                [self performSegueWithIdentifier:@"detailsViewSeque" sender:self];
            }
            
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];
            if ( labelString != nil) {
                [self.queryLabel setText:labelString];
            }
            [self.recordButton setEnabled:YES];
        });
    }
    }];
}








- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"detailsViewSeque"])
    {
        ResultsTableViewController *rtvc = [segue destinationViewController];
        [rtvc setData:self.searchData];
        [rtvc setQuery:transcript];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self setSearchData:nil];
    [self.queryLabel setText:@"What can Watson help you with today?"];
    [self.recordButton setEnabled:YES];
    shouldShowResults = YES;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:29 green:75 blue:109 alpha:1]];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}













@end
