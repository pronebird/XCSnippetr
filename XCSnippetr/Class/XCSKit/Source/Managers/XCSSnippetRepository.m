//
//  XCSSnippetRepository.m
//  XCSnippetr
//
//  Created by Ignacio Romero on 9/26/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSSnippetRepository.h"

static NSString const *XCSSnippetLanguageDomain = @"Xcode.SourceCodeLanguage";
static NSString const *XCSSnippetTemplateName = @"XCSSnippetTemplate";

@implementation XCSSnippetRepository

#pragma mark - Initialization

+ (instancetype)defaultRepository
{
    static XCSSnippetRepository *_defaultRepository;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultRepository = [[self alloc] init];
    });
    return _defaultRepository;
}

- (NSString *)snippetsDirectory
{
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    
    return [libraryDirectory stringByAppendingString:@"Developer/Xcode/UserData/CodeSnippets"];
}

- (void)_runShellCommand:(NSString *)commandLine completion:(void(^)(NSData *outData, NSData *errData))completion {
    NSPipe *stdOutputPipe = [[NSPipe alloc] init];
    NSPipe *stdErrorPipe = [[NSPipe alloc] init];
    NSTask *task = [[NSTask alloc] init];
    
    task.currentDirectoryPath = [self snippetsDirectory];
    task.launchPath = @"/bin/sh";
    task.arguments = @[ @"-c", [NSString stringWithFormat:@"\"%@\"", commandLine] ];
    task.standardOutput = stdOutputPipe;
    task.standardError = stdErrorPipe;
    
    NSMutableData *outputData = [[NSMutableData alloc] init];
    NSMutableData *errorData = [[NSMutableData alloc] init];
    
    stdOutputPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if(data) {
            [outputData appendData:data];
        }
    };
    
    stdErrorPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if(data) {
            [errorData appendData:data];
        }
    };
    
    task.terminationHandler = ^(NSTask *task) {
        if(completion) {
            completion(outputData, errorData);
        }
    };
    
    [task launch];
    
    [stdOutputPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];
}

- (void)saveSnippet:(XCSSnippet *)snippet completion:(void (^)(NSString *filePath, NSError *error))completion
{
    NSString *identifier = [NSUUID UUID].UUIDString;
    NSString *fileName = [NSString stringWithFormat:@"%@.codesnippet", identifier];
    NSString *filePath = [[self snippetsDirectory] stringByAppendingPathComponent:fileName];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *plistPath = [bundle pathForResource:[XCSSnippetTemplateName copy] ofType:@"plist"];
    
    NSMutableDictionary *template = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];

    template[@"IDECodeSnippetContents"] = snippet.content;
    template[@"IDECodeSnippetIdentifier"] = identifier;
    template[@"IDECodeSnippetLanguage"] = [NSString stringWithFormat:@"%@.%@", XCSSnippetLanguageDomain, snippet.typeHumanString];
    template[@"IDECodeSnippetTitle"] = snippet.title;
    template[@"IDECodeSnippetCompletionPrefix"] = snippet.title;
    
    if ([template writeToURL:[NSURL fileURLWithPath:filePath] atomically:YES]) {
        if (completion) {
            completion(filePath, nil);
        }
    }
    else if (completion) {
        completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotCreateFile userInfo:nil]);
    }
}

- (void)synchronize:(void(^)(BOOL success, NSError *error))completion
{
    NSString *snippetsDirectory = [self snippetsDirectory];
    NSString *gitDirectory = [snippetsDirectory stringByAppendingPathComponent:@".git"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:gitDirectory]) {
        [self _setupGitRepository];
    }
    else {
        
    }
}

- (void)_setupGitRepository {
    NSString *command = @"git init";
    
    [self _runShellCommand:command completion:^(NSData *outData, NSData *errData) {
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        NSString *errString = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
        
        NSLog(@"outString = %@", outString);
        NSLog(@"errString = %@", errString);
    }];
}

@end
