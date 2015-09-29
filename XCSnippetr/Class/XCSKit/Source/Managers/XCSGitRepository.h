//
//  XCSGitRepository.h
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCSGitOperation.h"

@interface XCSGitRepository : NSObject

@property (readonly) NSString *path;

- (instancetype)initWithRepositoryAtPath:(NSString *)path;

- (void)scheduleOperation:(XCSGitOperation *)operation;
- (void)scheduleOperations:(NSArray<XCSGitOperation *> *)operations;

- (BOOL)exists;

- (XCSGitOperation *)create;
- (XCSGitOperation *)stageAll;
- (XCSGitOperation *)commitWithMessage:(NSString *)message;

- (XCSGitOperation *)push;
- (XCSGitOperation *)pull;

@end
