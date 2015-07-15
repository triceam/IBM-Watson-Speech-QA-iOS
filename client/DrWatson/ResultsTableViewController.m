//
//  ResultsTableViewController.m
//  DrWatson
//
//  Created by Andrew Trice on 6/18/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import "ResultsTableViewController.h"
#import "SearchResultTableViewCell.h"
#import "SpeechManager.h"

@interface ResultsTableViewController ()

@end

@implementation ResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.data count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultTableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"WatsonSearchResultCell" forIndexPath:indexPath];
    
    NSDictionary *item = [self.data objectAtIndex:indexPath.row];
    [cell setData:item];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.data objectAtIndex:indexPath.row];
    [[SpeechManager sharedInstance] speak:item];
}



- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setData:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SpeechManager sharedInstance] stop];
    });
    
}

@end
