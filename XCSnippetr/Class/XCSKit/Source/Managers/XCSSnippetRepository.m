//
//  XCSSnippetRepository.m
//  XCSnippetr
//
//  Created by Ignacio Romero on 9/26/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

#import "XCSSnippetRepository.h"
#import "XCSGitRepository.h"

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
    
    return [libraryDirectory stringByAppendingPathComponent:@"Developer/Xcode/UserData/CodeSnippets"];
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
    XCSGitRepository *repo = [[XCSGitRepository alloc] initWithRepositoryAtPath:[self snippetsDirectory]];
    
    if([repo exists]) {
        // stage all/commit/pull+merge/push
        
        XCSGitOperation *stageOperation = [repo stageAll];
        XCSGitOperation *commitOperation = [repo commitWithMessage:@"Update snippets"];
        [commitOperation addDependency:stageOperation];
        
        XCSGitOperation *pullOperation = [repo pull];
        [pullOperation addDependency:commitOperation];
        
        XCSGitOperation *pushOperation = [repo push];
        pushOperation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completion) {
                    completion(YES, nil);
                }
            });
        };
        [pushOperation addDependency:pullOperation];
        
        [repo scheduleOperations:@[ stageOperation, commitOperation, pullOperation, pushOperation ]];
    }
    else {
        // init/stage all/commit/push?
        
        XCSGitOperation *createOperation = [repo create];
        
        XCSGitOperation *stageOperation = [repo stageAll];
        [stageOperation addDependency:createOperation];
        
        XCSGitOperation *commitOperation = [repo commitWithMessage:@"Initial import"];
        commitOperation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completion) {
                    completion(YES, nil);
                }
            });
        };
        [commitOperation addDependency:stageOperation];
        
        [repo scheduleOperations:@[ createOperation, stageOperation, commitOperation ]];
    }
}

@end
