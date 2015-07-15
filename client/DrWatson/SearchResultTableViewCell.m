//
//  SearchResultTableViewCell.m
//  DrWatson
//
//  Created by Andrew Trice on 6/18/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import "SearchResultTableViewCell.h"

@implementation SearchResultTableViewCell

@synthesize data = _data;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setData:(NSDictionary *)data {
    _data = data;
    [self.contentLabel setText:[_data objectForKey:@"text"]];
    
    float value = [[data objectForKey:@"value"] floatValue];
    NSString *confidence = [NSString stringWithFormat:@"Confidence: %.02f%%", value*100];
    [self.metadataLabel setText:confidence];
}

@end
