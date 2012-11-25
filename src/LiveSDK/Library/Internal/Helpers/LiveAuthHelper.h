//
//  LiveAuthHelper.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveConnectSession.h"

@interface LiveAuthHelper : NSObject

+ (NSBundle *) getSDKBundle;

#if (TARGET_OS_MAC && !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE))
+ (NSImage *) getBackButtonImage;
#else
+ (UIImage *) getBackButtonImage;
#endif

+ (NSArray *) normalizeScopes:(NSArray *)scopes;

+ (BOOL) isScopes:(NSArray *)scopes1
         subSetOf:(NSArray *)scopes2;

+ (NSURL *) buildAuthUrlWithClientId:(NSString *)clientId
                         redirectUri:(NSString *)redirectUri
                              scopes:(NSArray *)scopes;

+ (NSData *) buildGetTokenBodyDataWithClientId:(NSString *)clientId
                                   redirectUri:(NSString *)redirectUri
                                      authCode:(NSString *)authCode;

+ (NSData *) buildRefreshTokenBodyDataWithClientId:(NSString *)clientId
                                      refreshToken:(NSString *)refreshToken
                                             scope:(NSArray *)scopes;

+ (void) clearAuthCookie;

+ (NSError *) createAuthError:(NSInteger)code
                         info:(NSDictionary *)info;

+ (NSError *) createAuthError:(NSInteger)code
                     errorStr:(NSString *)errorStr
                  description:(NSString *)description
                   innerError:(NSError *)innerError;

+ (NSURL *) getRetrieveTokenUrl;

+ (NSString *) getDefaultRedirectUrlString;

#if (!TARGET_OS_MAC )
// ios speific
+ (BOOL) isiPad;
#endif

+ (id) readAuthResponse:(NSData *)data;

+ (BOOL) isSessionValid:(LiveConnectSession *)session;

+ (BOOL) shouldRefreshToken:(LiveConnectSession *)session
               refreshToken:(NSString *)refreshToken;

+ (void) overrideLoginServer:(NSString *)loginServer
                   apiServer:(NSString *)apiServer;

+ (NSDictionary *) dictionaryWithResponseString:(NSString *)responseStr;

+ (NSString *) encodedQueryParametersForDictionary:(NSDictionary *)dict;

@end
