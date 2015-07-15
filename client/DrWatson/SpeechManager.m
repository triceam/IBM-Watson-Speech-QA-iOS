//
//  SpeechManager.m
//  DrWatson
//
//  Created by Andrew Trice on 6/18/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import "SpeechManager.h"

@implementation SpeechManager


@synthesize currentData;
@synthesize synthesizer = _synthesizer;



//-(void) getList:(void (^)(NSArray*))callback;


+(SpeechManager*) sharedInstance {
    
    static SpeechManager *instance = nil;
    SpeechManager *strongInstance = instance;
    
    @synchronized(self) {
        if (strongInstance == nil) {
            strongInstance = [[[self class] alloc] init];
            instance = strongInstance;
        }
    }
    
    return strongInstance;
}


- (id)init {
    self = [super init];
    if (self) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return self;
}


-(void) speak:(NSDictionary*)data {
    
    BOOL speaking = self.synthesizer.isSpeaking;
    if (speaking)
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    if (!speaking || currentData != data) {
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        NSString *text = [data objectForKey:@"text"];
        NSArray *sentences = [text componentsSeparatedByString:@"."];
        
        for (int i=0;i<[sentences count]; i++) {
            AVSpeechUtterance *utterance = [AVSpeechUtterance
                                            speechUtteranceWithString:[sentences objectAtIndex:i]];
            
            utterance.rate = 0.22;
            utterance.preUtteranceDelay = 0.0;
            utterance.volume = 1.0;
            
            [self.synthesizer speakUtterance:utterance];
        }
    }
    currentData = data;
}


-(void) stop {
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

@end
