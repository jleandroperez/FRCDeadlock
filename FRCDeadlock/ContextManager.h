//
//  ContextManager.h
//  FRCDeadlock
//
//  Created by Jorge Leandro Perez on 1/5/15.
//  Copyright (c) 2015 Lantean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>



@interface ContextManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext          *mainManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *writerManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

+ (instancetype)sharedInstance;

- (void)saveContext;

@end
