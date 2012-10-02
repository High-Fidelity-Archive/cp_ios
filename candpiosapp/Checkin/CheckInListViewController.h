//
//  CheckInListViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.

#import <UIKit/UIKit.h>

@interface CheckInListViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *venues;

- (IBAction)closeWindow:(id)sender;
- (void)refreshLocations;

@end
