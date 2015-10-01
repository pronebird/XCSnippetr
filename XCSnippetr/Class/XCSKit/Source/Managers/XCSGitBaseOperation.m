//
//  XCSGitBaseOperation.m
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSGitBaseOperation.h"

@interface XCSGitBaseOperation ()

@property (nonatomic, getter = isFinished, readwrite)  BOOL finished;
@property (nonatomic, getter = isExecuting, readwrite) BOOL executing;
@property (nonatomic, getter = isFailed, readwrite) BOOL failed;

@end

@implementation XCSGitBaseOperation

@synthesize finished  = _finished;
@synthesize executing = _executing;
@synthesize failed = _failed;

- (id)init {
    self = [super init];
    if (self) {
        _finished  = NO;
        _executing = NO;
    }
    return self;
}

- (void)start {
    // cancel operation if any of dependent operations failed.
    for(NSOperation *operation in self.dependencies) {
        if(([operation isKindOfClass:[self class]] && [((__typeof(self))operation) isFailed]) || [operation isCancelled]) {
            self.failed = YES;
            [self cancel];
        }
    }
    
    if([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    
    [self main];
}

- (void)failWithExitCode:(int)exitCode {
    if(exitCode != 0) {
        self.failed = YES;
    }
}

- (void)completeOperation {
    self.executing = NO;
    self.finished  = YES;
}

#pragma mark - NSOperation methods

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    @synchronized(self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _finished;
    }
}

- (BOOL)isFailed {
    @synchronized(self) {
        return _failed;
    }
}

- (void)setExecuting:(BOOL)executing {
    @synchronized(self) {
        NSString *key = NSStringFromSelector(@selector(isExecuting));
        
        if (_executing != executing) {
            [self willChangeValueForKey:key];
            _executing = executing;
            [self didChangeValueForKey:key];
        }
    }
}

- (void)setFinished:(BOOL)finished {
    @synchronized(self) {
        NSString *key = NSStringFromSelector(@selector(isFinished));
        
        if (_finished != finished) {
            [self willChangeValueForKey:key];
            _finished = finished;
            [self didChangeValueForKey:key];
        }
    }
}

- (void)setFailed:(BOOL)failed {
    @synchronized(self) {
        NSString *key = NSStringFromSelector(@selector(isFailed));
        
        if (_failed != failed) {
            [self willChangeValueForKey:key];
            _failed = failed;
            [self didChangeValueForKey:key];
        }
    }
}

@end
