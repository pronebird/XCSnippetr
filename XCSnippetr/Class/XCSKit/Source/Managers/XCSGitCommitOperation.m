//
//  XCSGitCommitOperation.m
//  XCSnippetr
//
//  Created by pronebird on 10/1/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSGitCommitOperation.h"

@implementation XCSGitCommitOperation

- (void)failWithExitCode:(int)code {
    // git commit returns 1 when no files were staged
    if(code == 1) { return; }
    
    [super failWithExitCode:code];
}

@end
