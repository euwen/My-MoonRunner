//
//  PastRunsViewController.m
//  MoonRunner
//
//  Created by Youwen Yi on 1/21/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import "PastRunsViewController.h"
#import "RunCell.h"
#import "Run.h"
#import "DetailViewController.h"

@interface PastRunsViewController ()

@end

@implementation PastRunsViewController{

    NSMutableArray *runs;

}

@synthesize managedObjectContext;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Run"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error;
    NSArray *foundObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (foundObjects == nil) {
        NSLog(@"Fetch Error: %@", error);
        return;
    }
    
    runs = [NSMutableArray arrayWithArray:foundObjects];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return [runs count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Runs" forIndexPath:indexPath];
    
    // Configure the cell...
    
    [self configureCell:cell atIndexPath:indexPath];
    
    
    return cell;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{

    RunCell *runCell = (RunCell *)cell;
    Run *run = [runs objectAtIndex:indexPath.row];
    
    if (run.timestamp != nil) {
        //runCell.dateLabel.text = [NSString stringWithFormat:@"%@", run.timestamp];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        runCell.dateLabel.text = [formatter stringFromDate:run.timestamp];
        
    } else {
        runCell.dateLabel.text = @"No Timestamp";
    }
    
    if (run.duration != nil && run.distance != nil) {
        runCell.runDetailsLabel.text = [NSString stringWithFormat:@"Time: %i sec, Distance: %.2f m", [run.duration intValue], [run.distance doubleValue]];
        
    }

}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Run *_run = [runs objectAtIndex:indexPath.row];
        [runs removeObjectAtIndex:indexPath.row];
        
        [self.managedObjectContext deleteObject:_run];
        
        [self.managedObjectContext save:nil];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [tableView reloadData];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    DetailViewController *controller = segue.destinationViewController;
    
    NSIndexPath *indexPath= [self.tableView indexPathForCell:sender];
    
    Run *_run = [runs objectAtIndex:indexPath.row];
    [controller setRun:_run];
    
    // Pass the selected object to the new view controller.
}


@end
