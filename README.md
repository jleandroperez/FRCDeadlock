FRCDeadlock
===========

In this sample project, we'll demonstrate a deadlock triggered with FRC usage and Nested ManagedObjectContext's.

#### Background:
This sample app uses two NSManagedObjectContext instances:

- MainManagedObjectContext: Main concurrency, with its parent set to the WriterMOC
- WriterManagedObjectContext: Private Queue concurrency, attached to the PSC

If there is a NSFetchedResultsController instance attached to the MainMOC, running `performFetch:`, exactly at the same moment when there is a writerMOC running a FetchRequest, the app will experience a deadlock.

#### Steps:
1. Launch the app (Simulator or Device, any of them will work).
2. Hit the button "Trigger", located in the navigation bar.

As a result the main thread will get locked.

