//
//  SpeechManager.h
//  DrWatson
//
//  Created by Andrew Trice on 6/18/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SpeechManager : NSObject

@property (nonatomic, strong) NSDictionary *currentData;
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

+(id) sharedInstance;

-(void) speak:(NSDictionary*)data;
-(void) stop;

@end
