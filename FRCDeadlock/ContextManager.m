//
//  ContextManager.m
//  FRCDeadlock
//
//  Created by Jorge Leandro Perez on 1/5/15.
//  Copyright (c) 2015 Lantean. All rights reserved.
//

#import "ContextManager.h"



@interface ContextManager ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext          *mainManagedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectContext          *writerManagedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@end



@implementation ContextManager

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FRCDeadlock" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FRCDeadlock.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)writerManagedObjectContext
{
    if (_writerManagedObjectContext != nil) {
        return _writerManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    NSManagedObjectContext *context     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator  = coordinator;
    _writerManagedObjectContext         = context;
    
    return _writerManagedObjectContext;
}

- (NSManagedObjectContext *)mainManagedObjectContext
{
    if (_mainManagedObjectContext != nil) {
        return _mainManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    NSManagedObjectContext *context     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.parentContext               = self.writerManagedObjectContext;
    _mainManagedObjectContext           = context;
    
    return _mainManagedObjectContext;
}


- (void)saveContext
{
    [self.mainManagedObjectContext save:nil];
    [self.writerManagedObjectContext performBlock:^{
        [self.writerManagedObjectContext save:nil];
    }];
}


#pragma mark - Static Helpers

+ (instancetype)sharedInstance
{
    static id _sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    
    return _sharedInstance;
}

@end
