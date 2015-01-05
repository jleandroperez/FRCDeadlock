//
//  MasterViewController.m
//  FRCDeadlock
//
//  Created by Jorge Leandro Perez on 1/5/15.
//  Copyright (c) 2015 Lantean. All rights reserved.
//

#import "MasterViewController.h"
#import "ContextManager.h"
#import "Event.h"



static NSInteger const DeadlockSections         = 20;
static NSInteger const DeadlockCountPerSection  = 10;


@interface MasterViewController () <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController    *fetchedResultsController;
@end


@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Trigger"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(triggerDeadlock)];
}

- (void)triggerDeadlock
{
    [self insertSampleEntities:DeadlockCountPerSection sections:DeadlockSections];
    [self beginRunningBackgroundRequests];
    [self beginRefreshingResultsController];
}

- (void)insertSampleEntities:(NSInteger)count sections:(NSInteger)sections
{
    NSManagedObjectContext *writerMOC   = [[ContextManager sharedInstance] writerManagedObjectContext];
    NSEntityDescription *entity         = self.fetchedResultsController.fetchRequest.entity;
    
    [writerMOC performBlock:^{
        
        for (NSInteger section = 0; ++section <= sections; )
        {
            for (NSInteger i = 0; ++i <= count; )
            {
                Event *newEvent         = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:writerMOC];
                newEvent.timeStamp      = [NSDate date];
                newEvent.sectionName    = [NSString stringWithFormat:@"Section %ld", section];
            }
        }
        
        [writerMOC save:nil];
        NSLog(@"<> Successfully Inserted %ld objects", count);
    }];
}

- (void)beginRefreshingResultsController
{
    NSLog(@"<< Refresh Starts");
    [self.fetchedResultsController performFetch:nil];
    NSLog(@">> Refresh Ends");
    
    [self performSelector:@selector(beginRefreshingResultsController) withObject:nil afterDelay:0.3];
}

- (void)beginRunningBackgroundRequests
{
    NSManagedObjectContext *writerMOC   = [[ContextManager sharedInstance] writerManagedObjectContext];
    NSEntityDescription *entity         = self.fetchedResultsController.fetchRequest.entity;
    
    [writerMOC performBlock:^{
        NSLog(@"<< Update Starts");
        
        NSFetchRequest *request         = [[NSFetchRequest alloc] initWithEntityName:entity.name];
        request.returnsObjectsAsFaults  = false;
        
        NSArray *results                = [writerMOC executeFetchRequest:request error:nil];
        
        for (NSManagedObject *updatedObject in results)
        {
            [updatedObject setValue:[NSDate date] forKey:@"timeStamp"];
        }

        [writerMOC save:nil];

        dispatch_sync(dispatch_get_main_queue(), ^{
            // This call is just to show that the FRC gets 100% locked whenever a BG worker is running a block
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self beginRunningBackgroundRequests];
        });
        
        NSLog(@">> Update Ends");
    }];
}



#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Event *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [object.timeStamp description];
}



#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainManagedObjectContext];
    NSFetchRequest *fetchRequest    = [[NSFetchRequest alloc] init];
    fetchRequest.entity             = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:mainMOC];
    fetchRequest.fetchBatchSize     = 20;
    fetchRequest.sortDescriptors    = @[ [[NSSortDescriptor alloc] initWithKey:@"sectionName" ascending:false] ];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:mainMOC sectionNameKeyPath:@"sectionName" cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
