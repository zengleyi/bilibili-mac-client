//
//  BrowserHistory.m
//  bilibili
//
//  Created by TYPCN on 2016/1/25.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "BrowserHistory.h"
#import "HotURL.h"
#import "PJTernarySearchTree.h"
#import <FMDB/FMDB.h>

@implementation BrowserHistory{
    FMDatabase *db;
    HotURL *huc;
}

+ (instancetype)sharedManager {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    if (self = [super init])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *ASDir = [paths firstObject];
        NSString *path = [NSString stringWithFormat:@"%@/com.typcn.bilibili/History.db",ASDir];
        db = [FMDatabase databaseWithPath:path];
        if (![db open]) {
            NSLog(@"[HistoryManager] Can't open database: %@", [db lastErrorMessage]);
            [db close];
            return NULL;
        }else{
            [self initTable];
            huc = [[HotURL alloc] initWithDatabase:db];
            NSLog(@"[HistoryManager] Database load success");
        }
    }
    return self;
}

- (BOOL)initTable{
    NSString *sql = @"CREATE TABLE IF NOT EXISTS browse_history (id integer primary key autoincrement,title char(64),url char(256),time integer,status integer);";

    BOOL success = [db executeStatements:sql];
    if(!success){
        NSLog(@"[HistoryManager] Table create failed: %@",[db lastErrorMessage]);
        return false;
    }
    return true;
}

- (int64_t)insertURL:(NSString *)URL title:(NSString *)title{

    BOOL success = [db executeUpdateWithFormat:@"INSERT INTO browse_history (title,url,time,status) VALUES (%@, %@, %ld, 1)", title, URL, time(0)];
    if (!success) {
        NSLog(@"[HistoryManager] History insert failed: %@", [db lastErrorMessage]);
        return -1;
    }
    int64_t rid = [db lastInsertRowId];
    
    [huc appendURL:URL];
    
    return rid;
}

- (bool)setStatus:(int64_t)status forID:(int64_t)ID{
    BOOL success = [db executeUpdate:@"UPDATE browse_history SET status=? WHERE id=?", @(status), @(ID)];
    if (!success) {
        NSLog(@"[HistoryManager] History update failed: %@", [db lastErrorMessage]);
        return false;
    }
    return true;
}

- (bool)deleteItem:(int64_t)ID{
    BOOL success = [db executeUpdate:@"DELETE FROM browse_history WHERE id=?", @(ID)];
    if (!success) {
        NSLog(@"[HistoryManager] History update failed: %@", [db lastErrorMessage]);
        return false;
    }
    return true;
}

- (void)dealloc{
    [db close];
    NSLog(@"[HistoryManager] Shutting down");
}
//
//PJTernarySearchTree *tree = [PJTernarySearchTree sharedTree];
//dispatch_async([tree sharedIndexQueue], ^(void){
//    [tree insertString:url];
//});

@end
