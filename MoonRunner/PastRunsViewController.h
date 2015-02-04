//
//  PastRunsViewController.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/21/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface PastRunsViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property(nonatomic, strong)NSManagedObjectContext *managedObjectContext;

@end
