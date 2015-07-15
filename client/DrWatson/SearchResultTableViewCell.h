//
//  SearchResultTableViewCell.h
//  DrWatson
//
//  Created by Andrew Trice on 6/18/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultTableViewCell : UITableViewCell


@property (nonatomic, weak) IBOutlet UILabel *metadataLabel;
@property (nonatomic, weak) IBOutlet UILabel *contentLabel;
@property (nonatomic, strong) NSDictionary *data;

@end
