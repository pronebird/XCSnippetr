//
//  XCSGitBaseOperation.h
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCSGitBaseOperation : NSOperation

@property (nonatomic, getter = isFailed, readonly) BOOL failed;

- (void)failWithExitCode:(int)exitCode;
- (void)completeOperation;

@end