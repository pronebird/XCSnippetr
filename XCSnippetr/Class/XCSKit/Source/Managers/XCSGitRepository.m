//
//  XCSGitRepository.m
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSGitRepository.h"

static NSString * kGitBinaryPath = @"/usr/bin/git";

static dispatch_queue_t dispatchQueue;

@interface XCSGitRepository ()

@property (readwrite) NSString *path;

@property NSOperationQueue *operationQueue;

@end

@implementation XCSGitRepository

- (instancetype)initWithRepositoryAtPath:(NSString *)path {
    if(self = [super init]) {
        self.path = path;
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.suspended = NO;
    }
    return self;
}

- (void)scheduleOperation:(XCSGitOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)scheduleOperations:(NSArray<XCSGitOperation *> *)operations {
    [self.operationQueue addOperations:operations waitUntilFinished:NO];
}

- (BOOL)exists {
    NSString *gitDirectory = [self.path stringByAppendingPathComponent:@".git"];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:gitDirectory];
}

- (XCSGitOperation *)create {
    NSArray<NSString *> *arguments = @[ @"init" ];
    XCSGitOperation *operation = [[XCSGitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];
    
    return operation;
}

- (XCSGitOperation *)stageAll {
    NSArray<NSString *> *arguments = @[ @"add", @"-A" ];
    XCSGitOperation *operation = [[XCSGitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];

    return operation;
}

- (XCSGitCommitOperation *)commitWithMessage:(NSString *)message {
    NSParameterAssert(message);
    
    NSArray<NSString *> *arguments = @[ @"commit", @"-m", message ];
    XCSGitCommitOperation *operation = [[XCSGitCommitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];
    
    return operation;
}

- (XCSGitOperation *)push {
    NSArray<NSString *> *arguments = @[ @"push" ];
    XCSGitOperation *operation = [[XCSGitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];
    
    return operation;
}

- (XCSGitOperation *)pull {
    NSArray<NSString *> *arguments = @[ @"pull" ];
    XCSGitOperation *operation = [[XCSGitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];
    
    return operation;
}

- (XCSGitOperation *)addRemote:(NSString *)name withURL:(NSString *)url {
    NSParameterAssert(name);
    NSParameterAssert(url);
    
    NSArray<NSString *> *arguments = @[ @"remote", @"add", name, url ];
    XCSGitOperation *operation = [[XCSGitOperation alloc] initWithLaunchPath:kGitBinaryPath currentDirectoryPath:self.path arguments:arguments];
    
    return operation;
}

@end
