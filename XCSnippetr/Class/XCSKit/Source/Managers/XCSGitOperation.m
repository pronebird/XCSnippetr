//
//  XCSGitOperation.m
//  XCSnippetr
//
//  Created by pronebird on 9/29/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSGitOperation.h"

static dispatch_queue_t dispatchQueue;

@interface XCSGitOperation ()

@property (readwrite) NSTask *task;
@property (readwrite) NSString *outputString;
@property (readwrite) NSString *errorString;

@property NSString *launchPath;
@property NSString *currentDirectoryPath;
@property NSArray<NSString *> *arguments;

@end

@implementation XCSGitOperation

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatchQueue = dispatch_queue_create("XCSGitRepository.Queue", DISPATCH_QUEUE_SERIAL);
    });
}

- (instancetype)initWithLaunchPath:(NSString *)launchPath currentDirectoryPath:(NSString *)currentDirectoryPath arguments:(NSArray<NSString *> *)arguments {
    if(self = [super init]) {
        self.launchPath = launchPath;
        self.currentDirectoryPath = currentDirectoryPath;
        self.arguments = arguments;
        
        self.name = [NSString stringWithFormat:@"git %@", [arguments componentsJoinedByString:@" "]];
    }
    return self;
}

- (void)main {
    NSParameterAssert(self.task == nil);
    
    __weak __typeof(self) weakSelf = self;
    
    NSPipe *stdOutputPipe = [NSPipe pipe];
    NSPipe *stdErrorPipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    
    task.currentDirectoryPath = self.currentDirectoryPath;
    task.launchPath = self.launchPath;
    task.arguments = self.arguments;
    task.standardOutput = stdOutputPipe;
    task.standardError = stdErrorPipe;
    
    NSMutableData *outputData = [[NSMutableData alloc] init];
    NSMutableData *errorData = [[NSMutableData alloc] init];
    
    stdOutputPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        dispatch_async(dispatchQueue, ^{
            NSData *data = [handle availableData];
            [outputData appendData:data];
        });
    };
    
    stdErrorPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        dispatch_async(dispatchQueue, ^{
            NSData *data = [handle availableData];
            [errorData appendData:data];
        });
    };
    
    task.terminationHandler = ^(NSTask *task) {
        dispatch_async(dispatchQueue, ^{
            __strong __typeof(self) strongSelf = weakSelf;
            
            strongSelf.outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
            strongSelf.errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            
            NSLog(@"stdout: %@", self.outputString);
            NSLog(@"stderr: %@", self.errorString);
            NSLog(@"terminationStatus = %d", task.terminationStatus);
            
            [strongSelf completeOperation];
        });
    };
    
    NSLog(@"Run %@ at %@ with arguments: %@", task.launchPath, task.currentDirectoryPath, task.arguments);
    
    self.task = task;
    
    [task launch];
}

- (void)_resetTask {
    [self.task.standardOutput fileHandleForReading].readabilityHandler = nil;
    [self.task.standardError fileHandleForReading].readabilityHandler = nil;
    self.task.terminationHandler = nil;
}

- (void)completeOperation {
    [super completeOperation];
    [self _resetTask];
}

- (void)cancel {
    [self _resetTask];
    
    [self.task interrupt];
    [self.task terminate];
    
    [super cancel];
}

@end
