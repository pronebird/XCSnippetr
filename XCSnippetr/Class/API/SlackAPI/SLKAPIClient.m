//
//  XCSnippetr
//  https://github.com/dzenbot/XCSnippetr
//
//  Created by Ignacio Romero Zurbuchen on 13/6/15
//  Copyright (c) 2015 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "SLKAPIClient.h"

#import "XCSAccount.h"
#import "XCSSnippet.h"
#import "SLKRoom.h"
#import "XCSMacros.h"

@implementation SLKAPIClient

#pragma mark - SLKAPIClient

- (void)authWithToken:(NSString *)token completion:(void (^)(XCSAccount *account, NSError *error))completion
{
    if (!isNonEmptyString(token)) {
        return;
    }
    
    NSDictionary *params = @{kSlackAPIParamToken: token};
    
    [self post:kSlackAPIMethodAuthTest params:params completion:^(id response, NSError *error) {
        
        XCSAccount *account = nil;
        
        if (!error) {
            account = [[XCSAccount alloc] initWithResponse:response service:XCSServiceSlack];
            account.accessToken = token;
        }
        
        if (completion) {
            completion(account, error);
        }
    }];
}

- (void)getAvailableRooms:(void (^)(NSDictionary *rooms, NSError *error))completion
{
    NSString *teamId = [XCSAccount currentAccount].teamId;
    
    if (!isNonEmptyString(teamId)) {
        return;
    }
    
    NSDictionary *params = @{kSlackAPIParamTeam: teamId};
    
    [self post:kSlackAPIMethodRTMStart params:params completion:^(id response, NSError *error) {
        
        if (completion) {
            completion([SLKRoom roomsFromResponse:response], error);
        }
    }];
}

- (void)uploadSnippet:(XCSSnippet *)snippet completion:(void (^)(NSDictionary *JSON, NSError *error))completion
{
    if (!snippet) {
        return;
    }
    
    NSDictionary *params = [snippet params];
    NSString *path = snippet.uploadAsSnippet ? kSlackAPIMethodFilesUpload : kSlackAPIMethodChatPostMessage;
    
    [self post:path params:params completion:completion];
}


#pragma mark - XCSServiceAPIProtocol

- (NSMutableURLRequest *)requestfForPath:(NSString *)path andParams:(NSDictionary *)params
{
    NSMutableDictionary *parameters = [params mutableCopy];
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@%@", kSlackAPIBaseUrl, path];
    
    NSString *accessToken = [XCSAccount currentAccount].accessToken;
    
    if (accessToken && ![path isEqualToString:kSlackAPIMethodAuthTest]) {
        [parameters setObject:accessToken forKey:kSlackAPIParamToken];
    }
    
    for (int i = 0; i < [parameters allKeys].count; i++) {
        
        if (i == 0) {
            [url appendString:@"?"];
        }
        else {
            [url appendString:@"&"];
        }
        
        NSString *key = [parameters allKeys][i];
        [url appendFormat:@"%@=%@", key, NSStringEscapedFrom(parameters[key])];
    }
    
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
}

@end
