//
//  ViewController.m
//  DrWatson
//
//  Created by Andrew Trice on 6/15/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end


@implementation ViewController

@synthesize searchData;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.activityView setColor:[UIColor whiteColor]];
    [self.activityView setHidden:YES];
    
    logger = [IMFLogger loggerForName:@"ViewController"];
    
    NSString *server = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Backend_Route"];
    transcribeURL = [NSString stringWithFormat:@"%@/transcribe", server];
    askURL = [NSString stringWithFormat:@"%@/ask", server];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordButtonPressed:(id)sender {
    
    if (audioRecorder == nil || !audioRecorder.recording) {
        [self setMicActiveState];
    }
    else {
        [self setMicInactiveState];
    }
}

-(void) setMicActiveState {
    
    [logger logDebugWithMessages:@"setMicActiveState"];
    if (!self.recordButton.selected) {
        self.recordButton.selected = YES;
        [self.queryLabel setText:@"What can Watson help you with today?"];
        
        [self startRecording];
    }
}

-(void) setMicInactiveState {
    
    [logger logDebugWithMessages:@"setMicInactiveState"];
    self.recordButton.selected = NO;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.queryLabel setText:@"Let me check that for you..."];
    
    [self stopRecording];
}


-(IBAction) startRecording
{
    [logger logDebugWithMessages:@"startRecording"];
    
    audioRecorder = nil;
    
    // Init audio with record capability
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //play "BeginRecording" sound
    AudioServicesPlaySystemSound(1113);
    
    //wait till after the sound plays before starting recording (350ms)
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.35);
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
        
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
        
        [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat:16000.0] forKey: AVSampleRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        [recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"audio.wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        NSError *error = nil;
        audioRecorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
        
        [audioRecorder setMeteringEnabled:YES];
        [self startMeterTimer];
        lastActive = [NSDate date];
        
        if ([audioRecorder prepareToRecord] == YES){
            [audioRecorder record];
        }else {
            [logger logErrorWithMessages:[error localizedDescription]];
        }
        [logger logDebugWithMessages:@"recording (in background thread)"];
    });
    
}

-(IBAction) stopRecording
{
    [logger logDebugWithMessages:@"stopRecording"];
    [self stopMeterTimer];
    
    //stop recording in a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        [audioRecorder stop];
        [audioSession setActive:NO error:&error];
        [logger logDebugWithMessages:@"stopped"];
        
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        //play "EndRecording" sound
        AudioServicesPlaySystemSound(1114);
        
        [self postToServer];
    });
}


- (void) startMeterTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60
                                                 target:self
                                               selector:@selector(tick:)
                                               userInfo:nil
                                                repeats:YES];
    });
}

- (void) stopMeterTimer {
    [timer invalidate];
    timer = nil;
}

- (void) tick:(NSTimer *) timer {
    
    [audioRecorder updateMeters];
    float db = [audioRecorder averagePowerForChannel:0];
    db += MAX_DB;
    db = db < 0 ? 0 : db;
    db = db > MAX_DB ? MAX_DB : db;
    
    CGRect newFrame = self.meterView.frame;
    
    newFrame.size.width = self.view.frame.size.width;
    newFrame.size.height = self.view.frame.size.height * (db/MAX_DB);
    
    newFrame.origin.x = 0;
    newFrame.origin.y = self.view.frame.size.height - newFrame.size.height;
    [self.meterView setFrame:newFrame];
    
    
    if (db > SILENCE_DB) {
        lastActive = [NSDate date];
    }
    
    NSTimeInterval secondsElapsed = [[NSDate date] timeIntervalSinceDate:lastActive];
    
    if (secondsElapsed > SILENCE_DURATION) {
        [self setMicInactiveState];
    }

}




-(void) postToServer {
    
    //update ui in main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordButton setEnabled:NO];
    });
    
    [logger logInfoWithMessages:@"posting WAV to server..."];
    
    IMFResourceRequest * imfRequest = [IMFResourceRequest requestWithPath:transcribeURL method:@"POST"];
    NSData *data = [NSData dataWithContentsOfURL:audioRecorder.url];
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    NSString *boundary = @"------------------------------------------------------";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    [imfRequest setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:encoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"audio\"; filename=\"%@\"\r\n", @"audio.wav"] dataUsingEncoding:encoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"audio/wav"] dataUsingEncoding:encoding]];
    [body appendData:data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:encoding]];
    
    
    [imfRequest setHTTPBody:body];
    [imfRequest sendWithCompletionHandler:^(IMFResponse *response, NSError *error) {
        
        NSDictionary* json = response.responseJson;
        if (json == nil) {
            json = @{@"transcript":@""};
            [logger logErrorWithMessages:@"Unable to retrieve results from server.  %@", [error localizedDescription]];
        }
        
        NSString *resultString = [json objectForKey:@"transcript"];
        BOOL animating = YES;
        
        if ( error != nil ) {
            resultString = [NSString stringWithFormat:@"%@ Try again later.", [error localizedDescription]];
            animating = NO;
        }
        else if (resultString == nil || [resultString length] <= 0 || [resultString isEqualToString:@""]) {
            
            resultString = @"Sorry, I didn't catch that.  Try again?";
            animating = NO;
        }
        else {
            [self requestQA:resultString];
        }
        
        [logger logInfoWithMessages:@"Transcript: %@", resultString];
        
        //update ui in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if( !animating) {
                [self.activityView stopAnimating];
                [self.activityView setHidden:YES];
            }
            [self.queryLabel setText:resultString];
            [self.recordButton setEnabled:YES];
        });
    }];
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
    }];
}








- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"detailsViewSeque"])
    {
        ResultsTableViewController *rtvc = [segue destinationViewController];
        [rtvc setData:self.searchData];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self setSearchData:nil];
    [self.queryLabel setText:@"What can Watson help you with today?"];
    [self.recordButton setEnabled:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:29 green:75 blue:109 alpha:1]];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}













@end
