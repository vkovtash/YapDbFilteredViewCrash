//
//  YapDbFilteredViewCrashTests.m
//  YapDbFilteredViewCrashTests
//
//  Created by kovtash on 21.06.15.
//  Copyright (c) 2015 zim-team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseView.h>
#import <YapDatabase/YapDatabaseFilteredView.h>


static NSString *const objSortingKey = @"sortingKey";
static NSString *const key = @"obj_key";
static NSString *const collection = @"test_objects";
static NSString *const testViewName = @"TestView";
static NSString *const filteredTestViewName = @"FilteredTestView";


@interface YadDbFilteredViewCrashTests : XCTestCase

@end

@implementation YadDbFilteredViewCrashTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testObjGroupingWithFilterHit {
    YapDatabase *db = [self setupDbWithName:@"testObjGroupingWithFilterHit"
                                   grouping:[self newObjectGrouping]
                           isInFilteredView:YES];
    [self performWriteIntoDb:db];
    [self cleanUpDb:db];
}

- (void)testRowGroupingWithoutFilterHit {
    YapDatabase *db = [self setupDbWithName:@"testRowGroupingWithoutFilterHit"
                                   grouping:[self newRowGrouping]
                           isInFilteredView:NO];
    [self performWriteIntoDb:db];
    [self cleanUpDb:db];
}


/**
 That test thows "Unexpected key class."
 */
- (void)testObjGroupingWithoutFilterHit {
    YapDatabase *db = [self setupDbWithName:@"testObjGroupingWithoutFilterHit"
                                   grouping:[self newObjectGrouping]
                           isInFilteredView:NO];
    [self performWriteIntoDb:db];
    [self cleanUpDb:db];
}

- (void)performWriteIntoDb:(YapDatabase *)db {
    YapDatabaseConnection *connection = [db newConnection];
    
    [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSDictionary *obj = @{objSortingKey: @1};
        NSDictionary *metadata = @{};
        
        [transaction setObject:obj forKey:key inCollection:collection withMetadata:metadata];
    }];
    
    [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSDictionary *metadata = @{};
        
        [transaction replaceMetadata:metadata forKey:key inCollection:collection];
    }];
}

- (void)cleanUpDb:(YapDatabase *)db {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:db.databasePath]) {
        [manager removeItemAtPath:db.databasePath error:nil];
    }
    
    if ([manager fileExistsAtPath:db.databasePath_shm]) {
        [manager removeItemAtPath:db.databasePath_shm error:nil];
    }
    
    if ([manager fileExistsAtPath:db.databasePath_wal]) {
        [manager removeItemAtPath:db.databasePath_wal error:nil];
    }
}

- (YapDatabaseViewGrouping *)newObjectGrouping {
    return [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key,
                                                                NSDictionary *obj) {
        return collection;
    }];
}

- (YapDatabaseViewGrouping *)newRowGrouping {
    return [YapDatabaseViewGrouping withRowBlock:^NSString *(NSString *collection, NSString *key,
                                                             NSDictionary *obj, NSDictionary *metadata) {
        return collection;
    }];
}

- (NSString *)dbPathWithName:(NSString *)dbName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [baseDir stringByAppendingPathComponent:dbName];
}

- (YapDatabase *)setupDbWithName:(NSString *)dbName
                        grouping:(YapDatabaseViewGrouping *)grouping
                isInFilteredView:(BOOL)isInFilteredView {
    NSString *dbPath = [self dbPathWithName:dbName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:dbPath]) {
        [manager removeItemAtPath:dbPath error:nil];
    }
    
    YapDatabaseOptions *options = [YapDatabaseOptions new];
    options.corruptAction = YapDatabaseCorruptAction_Delete;
    
    YapDatabase *db = [[YapDatabase alloc] initWithPath:dbPath];
    
    YapDatabaseViewSorting *sorting =
    [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group,
                                                                NSString *collection1, NSString *key1, NSDictionary *object1,
                                                                NSString *collection2, NSString *key2, NSDictionary *object2) {
        return [object1[objSortingKey] compare:object2[objSortingKey]];
    }];
    
    YapDatabaseView *testView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    
    [db registerExtension:testView withName:testViewName];
    
    YapDatabaseViewFiltering *filtering =
    [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, NSDictionary *obj) {
        return isInFilteredView;
    }];
    
    YapDatabaseFilteredView *testFilteredView =
    [[YapDatabaseFilteredView alloc] initWithParentViewName:testViewName filtering:filtering];
    
    [db registerExtension:testFilteredView withName:filteredTestViewName];
    
    return db;
}

@end
