//
//  Event.h
//  FRCDeadlock
//
//  Created by Jorge Leandro Perez on 1/5/15.
//  Copyright (c) 2015 Lantean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * sectionName;

@end
