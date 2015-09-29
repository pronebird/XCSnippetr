//
//  XCSGitOperation.h
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSGitBaseOperation.h"

@interface XCSGitOperation : XCSGitBaseOperation

@property (readonly) NSTask *task;
@property (readonly) NSString *outputString;
@property (readonly) NSString *errorString;

- (instancetype)initWithLaunchPath:(NSString *)launchPath
              currentDirectoryPath:(NSString *)currentDirectoryPath
                         arguments:(NSArray<NSString *> *)arguments;

@end
