//
//  LiveAuthHelper.m
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import "LiveAuthHelper.h"
#import "LiveConstants.h"
#import "LiveConnectSession.h"
#import "JsonParser.h"
#import "StringHelper.h"
#import "UrlHelper.h"

NSString * LIVE_ENDPOINT_API_HOST = @"apis.live.net";
NSString * LIVE_ENDPOINT_LOGIN_HOST = @"login.live.com";

@implementation LiveAuthHelper

+ (NSBundle *) getSDKBundle
{
    NSString *sdkPath = [[NSBundle mainBundle] pathForResource:@"LiveSDK"
                                                        ofType:@"framework"];
    return (sdkPath)? [NSBundle bundleWithPath:sdkPath] : [NSBundle mainBundle];
}

#if (!TARGET_OS_MAC )
// ios speific
+ (UIImage *) getBackButtonImage
{
    NSString * path = [[NSBundle mainBundle] pathForResource:@"LiveSDK.framework/Resources/backArrow_black"
                                                      ofType:@"png"];
    if (path) {
        return [UIImage imageWithContentsOfFile:path];
    }
    else
    {
        return [UIImage imageNamed:@"backArrow_black"];
    }
}
#else

// Mac OS X speific
+ (NSImage *) getBackButtonImage
{

        return [NSImage imageNamed:@"backArrow_black"];
}
#endif

+ (NSArray *) normalizeScopes:(NSArray *)scopes
{
    NSMutableArray *normalScopes = [NSMutableArray array];
    for (NSUInteger i = 0; i < scopes.count; i++) 
    {
        NSString *scope = [scopes objectAtIndex:i];
        if (![StringHelper isNullOrEmpty:scope])
        {
            [normalScopes addObject: [scope lowercaseString]];
        }
    }
    
    return normalScopes;
}

+ (BOOL) isScopes:(NSArray *)scopes1
         subSetOf:(NSArray *)scopes2
{
    return [[NSSet setWithArray:scopes1] isSubsetOfSet:[NSSet setWithArray:scopes2]];
}

#if (!TARGET_OS_MAC )
// ios speific
+ (BOOL) isiPad
{
    return [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];
}
#endif

+ (NSString *) getAuthorizeUrl
{
    return [NSString stringWithFormat:@"https://%@/oauth20_authorize.srf", LIVE_ENDPOINT_LOGIN_HOST];
}

+ (NSURL *) getRetrieveTokenUrl
{
    return [NSURL URLWithString: [NSString stringWithFormat:@"https://%@/oauth20_token.srf", LIVE_ENDPOINT_LOGIN_HOST]];
}

+ (NSString *) getDefaultRedirectUrlString
{
    return [NSString stringWithFormat:@"https://%@/oauth20_desktop.srf", LIVE_ENDPOINT_LOGIN_HOST];
}

+ (NSString *) getAuthDisplayValue
{
#if (!TARGET_OS_MAC )
    // ios speific
    return [LiveAuthHelper isiPad] ? LIVE_AUTH_DISPLAY_IOS_TABLET : LIVE_AUTH_DISPLAY_IOS_PHONE;
#else
    return LIVE_AUTH_DISPLAY_IOS_TABLET;

#endif
    
}

+ (NSURL *) buildAuthUrlWithClientId:(NSString *)clientId
                         redirectUri:(NSString *)redirectUri
                              scopes:(NSArray *)scopes
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString * scopesString = [scopes componentsJoinedByString:@" "];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              clientId, LIVE_AUTH_CLIENTID,
                                        LIVE_AUTH_CODE, LIVE_AUTH_RESPONSE_TYPE,
                                           redirectUri, LIVE_AUTH_REDIRECT_URI,
                  [LiveAuthHelper getAuthDisplayValue], LIVE_AUTH_DISPLAY,
                                          scopesString, LIVE_AUTH_SCOPE,
                                              language, LIVE_AUTH_LOCALE,
                                                   nil];
    
    return [UrlHelper constructUrl:[LiveAuthHelper getAuthorizeUrl] params:parameters];
}

+ (NSData *) buildGetTokenBodyDataWithClientId:(NSString *)clientId
                                   redirectUri:(NSString *)redirectUri
                                      authCode:(NSString *)authCode
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                            clientId, LIVE_AUTH_CLIENTID,
                                                            authCode, LIVE_AUTH_CODE,
                                                         redirectUri, LIVE_AUTH_REDIRECT_URI,
                                       LIVE_AUTH_GRANT_TYPE_AUTHCODE, LIVE_AUTH_GRANT_TYPE,                                                                      
                                                                 nil];
    
    NSString *bodyString =  [UrlHelper encodeUrlParameters:parameters];
    
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *) buildRefreshTokenBodyDataWithClientId:(NSString *)clientId
                                      refreshToken:(NSString *)refreshToken
                                             scope:(NSArray *)scopes
{
    NSString * scopesString = [scopes componentsJoinedByString:@" "];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      clientId, LIVE_AUTH_CLIENTID,
                                                  refreshToken, LIVE_AUTH_REFRESH_TOKEN,
                                                  scopesString, LIVE_AUTH_SCOPE,
                                       LIVE_AUTH_REFRESH_TOKEN, LIVE_AUTH_GRANT_TYPE,                                    
                                       nil];
    
    NSString *bodyString =  [UrlHelper encodeUrlParameters:parameters];
    
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSError *) createAuthError:(NSInteger)code
                         info:(NSDictionary *)info
{
    return [NSError errorWithDomain:LIVE_ERROR_DOMAIN 
                               code:LIVE_ERROR_CODE_LOGIN_FAILED 
                           userInfo:info];
}

+ (NSError *) createAuthError:(NSInteger)code
                     errorStr:(NSString *)errorStr
                  description:(NSString *)description
                   innerError:(NSError *)innerError
{
    return [LiveAuthHelper createAuthError:code
                                      info:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 errorStr, LIVE_ERROR_KEY_ERROR,
                                              description, LIVE_ERROR_KEY_DESCRIPTION,
                                               innerError, LIVE_ERROR_KEY_INNER_ERROR,
                                                      nil]];
}

+ (id) readAuthResponse:(NSData *)data
{
    NSString* responseString = [[[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding]
                                autorelease];
    NSError *error = nil;
    NSDictionary *params = [MSJSONParser parseText:responseString 
                                             error:&error ];
    
    NSString * accessToken = [params valueForKey:LIVE_AUTH_ACCESS_TOKEN];
    if (accessToken != nil) 
    {
        NSString *authenticationToken = [params valueForKey: LIVE_AUTH_AUTHENTICATION_TOKEN];
        NSString *refreshToken = [params valueForKey: LIVE_AUTH_REFRESH_TOKEN];
        NSArray *scopes = [[params valueForKey:LIVE_AUTH_SCOPE] componentsSeparatedByString:@" "]; 
        NSString *expiresInStr = [params valueForKey:LIVE_AUTH_EXPIRES_IN];
        NSTimeInterval expiresIn = [expiresInStr doubleValue];
        NSDate *expires = [NSDate dateWithTimeIntervalSinceNow:expiresIn];
        
        LiveConnectSession *session = [[[LiveConnectSession alloc] initWithAccessToken:accessToken 
                                                                   authenticationToken:authenticationToken 
                                                                          refreshToken:refreshToken 
                                                                                scopes:scopes 
                                                                               expires:expires]
                                       autorelease];
        return session;
    }
    else 
    {
        if (error == nil)
        {
            return [LiveAuthHelper createAuthError:LIVE_ERROR_CODE_LOGIN_FAILED
                                              info:params];
        }
        else
        {
            return [LiveAuthHelper createAuthError:LIVE_ERROR_CODE_RETRIEVE_TOKEN_FAILED
                                          errorStr:LIVE_ERROR_CODE_S_RESPONSE_PARSING_FAILED 
                                       description:[NSString stringWithFormat:@"Unable to read response: %@", responseString]
                                        innerError:error];
        }
    }
}

+ (void) clearCookieForUrl:(NSString *)url
{
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* liveCookies = [cookies cookiesForURL:[NSURL URLWithString:url]];
    for (NSHTTPCookie* cookie in liveCookies) 
    {
        [cookies deleteCookie:cookie];
    }
}

+ (void) clearAuthCookie
{
    NSString *httpFormat =  @"http://%@";
    NSString *httpsFormat =  @"https://%@";
    NSMutableArray *authEndpoints = [NSMutableArray arrayWithObjects: 
                                     [NSString stringWithFormat: httpFormat, LIVE_ENDPOINT_LOGIN_HOST], 
                                     [NSString stringWithFormat: httpsFormat, LIVE_ENDPOINT_LOGIN_HOST],
                                     nil];
    
    for (NSString* authUrl in authEndpoints) 
    {
        [LiveAuthHelper clearCookieForUrl: authUrl];
    }
}

+ (BOOL) isSessionValid:(LiveConnectSession *)session
{
    // We give 3 seconds to allow for potential network transmission delay.
    return ([session.expires timeIntervalSinceNow] >= LIVE_AUTH_EXPIRE_VALUE_ADJUSTMENT);   
}

+ (BOOL) shouldRefreshToken:(LiveConnectSession *)session
               refreshToken:(NSString *)refreshToken
{
    BOOL hasRefreshToken = ![StringHelper isNullOrEmpty:refreshToken];
    if (session != nil) 
    {
        
        return hasRefreshToken && ([session.expires timeIntervalSinceNow] < LIVE_AUTH_REFRESH_TIME_BEFORE_EXPIRE);
    }
    else
    {
        // We have refresh token but no access token, we should get one.
        return hasRefreshToken;
    }
}

+ (void) overrideLoginServer:(NSString *)loginServer
                  apiServer:(NSString *)apiServer

{
    LIVE_ENDPOINT_LOGIN_HOST = loginServer;
    LIVE_ENDPOINT_API_HOST = apiServer;
}

+ (NSString *) unencodedOAuthParameterForString:(NSString *)str {
    NSString *plainStr = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return plainStr;
}

+ (NSDictionary *) dictionaryWithResponseString:(NSString *)responseStr {
    // Build a dictionary from a response string of the form
    // "cat=fluffy&dog=spot".  Missing or empty values are considered
    // empty strings; keys and values are percent-decoded.
    if (responseStr == nil) return nil;

    NSArray *items = [responseStr componentsSeparatedByString:@"&"];

    NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithCapacity:[items count]];

    for (NSString *item in items) {
        NSString *key = nil;
        NSString *value = @"";

        NSRange equalsRange = [item rangeOfString:@"="];
        if (equalsRange.location != NSNotFound) {
            // The parameter has at least one '='
            key = [item substringToIndex:equalsRange.location];

            // There are characters after the '='
            value = [item substringFromIndex:(equalsRange.location + 1)];
        } else {
            // The parameter has no '='
            key = item;
        }

        NSString *plainKey = [[self class] unencodedOAuthParameterForString:key];
        NSString *plainValue = [[self class] unencodedOAuthParameterForString:value];
        
        [responseDict setObject:plainValue forKey:plainKey];
    }
    
    return responseDict;
}

+ (NSString *) encodedOAuthValueForString:(NSString *)str {
    CFStringRef originalString = (CFStringRef) str;
    CFStringRef leaveUnescaped = NULL;
    CFStringRef forceEscaped =  CFSTR("!*'();:@&=+$,/?%#[]");

    CFStringRef escapedStr = NULL;
    if (str) {
        escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                             originalString,
                                                             leaveUnescaped,
                                                             forceEscaped,
                                                             kCFStringEncodingUTF8);
        [(id)CFMakeCollectable(escapedStr) autorelease];
    }
    
    return (NSString *)escapedStr;
}

+ (NSString *) encodedQueryParametersForDictionary:(NSDictionary *)dict {
    // Make a string like "cat=fluffy@dog=spot"
    NSMutableString *result = [NSMutableString string];
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *joiner = @"";
    for (NSString *key in sortedKeys) {
        NSString *value = [dict objectForKey:key];
        NSString *encodedValue = [self encodedOAuthValueForString:value];
        NSString *encodedKey = [self encodedOAuthValueForString:key];
        [result appendFormat:@"%@%@=%@", joiner, encodedKey, encodedValue];
        joiner = @"&";
    }
    return result;
}


@end
