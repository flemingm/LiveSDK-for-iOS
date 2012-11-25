//
//  LiveAuthStorage.m
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import "LiveAuthHelper.h"
#import "LiveAuthStorage.h"
#import "LiveConstants.h"
#import "LiveOAuthKeychain.h"

static NSString *sLiveKeychainItemName;

@interface LiveAuthStorage()

+ (NSDictionary *) dictionaryFromKeychainItemName:(NSString *)keychainItemName;

+ (BOOL) removeAuthFromKeychainForName:(NSString *)keychainItemName;

+ (void) saveToKeychainForName:(NSString *)keychainItemName
                  ccessibility:(CFTypeRef)accessibility
               liveAuthStorage:(LiveAuthStorage *)liveAuthStorage;

- (void) setKeysForResponseString:(NSString *)str;

- (void) setKeysForResponseDictionary:(NSDictionary *)dict;

- (NSString *) persistenceResponseString;

- (void) save;

@end

@implementation LiveAuthStorage

@synthesize refreshToken = _refreshToken;

+ (NSString *) keychainItemName
{
    return sLiveKeychainItemName;
}

+ (void) setKeychainItemName:(NSString *)keychainItemName
{
    [keychainItemName retain];
    [sLiveKeychainItemName release];
    sLiveKeychainItemName = keychainItemName;
}

- (id) initWithClientId:(NSString *)clientId
{
    self = [self initWithClientId:clientId keychainItemName:sLiveKeychainItemName];

    return self;
}

- (id) initWithClientId:(NSString *)clientId keychainItemName:(NSString *)keychainItemName
{
    self = [super init];
    if (self) 
    {
        _clientId = clientId;

        assert(clientId != nil);
        assert(sLiveKeychainItemName != nil);

        NSDictionary *dictionary = [[self class] dictionaryFromKeychainItemName:keychainItemName];
        if (dictionary != nil)
        {
            if ([clientId isEqualToString:[dictionary valueForKey:LIVE_AUTH_CLIENTID]])
            {
                _refreshToken = [[dictionary valueForKey:LIVE_AUTH_REFRESH_TOKEN] retain];
            }
            else
            {
                // The storage has a different client_id, flush it.
                [self save];
            }
        }
    }
    
    return self; 
}

- (void) dealloc
{
    [_clientId release];
    [_refreshToken release];
    
    [super dealloc];
}

- (void) save
{
    [[self class] saveToKeychainForName:sLiveKeychainItemName
                           ccessibility:NULL
                        liveAuthStorage:self];
}

- (void) setRefreshToken:(NSString *)refreshToken
{
    [_refreshToken release];
    _refreshToken = [refreshToken retain];

    [self save];
}

+ (NSDictionary *) dictionaryFromKeychainItemName:(NSString *)keychainItemName
{
    NSDictionary *dictionary = nil;
    LiveOAuthKeychain *keychain = [LiveOAuthKeychain defaultKeychain];
    NSString *password = [keychain passwordForService:keychainItemName
                                              account:LIVE_AUTH_ACCOUNT_NAME
                                                error:nil];
    if (password != nil) {
        dictionary = [LiveAuthHelper dictionaryWithResponseString:password];
    }
    return dictionary;
}

+ (BOOL) removeAuthFromKeychainForName:(NSString *)keychainItemName
{
    LiveOAuthKeychain *keychain = [LiveOAuthKeychain defaultKeychain];
    return [keychain removePasswordForService:keychainItemName
                                      account:LIVE_AUTH_ACCOUNT_NAME
                                        error:nil];
}

+ (void) saveToKeychainForName:(NSString *)keychainItemName
                  ccessibility:(CFTypeRef)accessibility
               liveAuthStorage:(LiveAuthStorage *)liveAuthStorage
{
    [self removeAuthFromKeychainForName:keychainItemName];

    NSString *password = [liveAuthStorage persistenceResponseString];

#if (TARGET_OS_MAC && !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE))
    
    LiveOAuthKeychain *keychain = [LiveOAuthKeychain defaultKeychain];
    
    [keychain setPassword:password
               forService:keychainItemName
            accessibility:accessibility
                  account:LIVE_AUTH_ACCOUNT_NAME
                    error:nil];
    
#else
    if (accessibility == NULL
        && &kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly != NULL) {
        accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    }
 

    LiveOAuthKeychain *keychain = [LiveOAuthKeychain defaultKeychain];
    [keychain setPassword:password
               forService:keychainItemName
            accessibility:accessibility
                  account:LIVE_AUTH_ACCOUNT_NAME
                    error:nil];
#endif
}

- (void) setKeysForResponseString:(NSString *)str
{
    NSDictionary *dict = [LiveAuthHelper dictionaryWithResponseString:str];
    [self setKeysForResponseDictionary:dict];
}

- (void) setKeysForResponseDictionary:(NSDictionary *)dict
{
    if (dict == nil) return;
    _clientId = [dict objectForKey:LIVE_AUTH_CLIENTID];
    _refreshToken = [dict objectForKey:LIVE_AUTH_REFRESH_TOKEN];
}

- (NSString *) persistenceResponseString
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:_clientId forKey:LIVE_AUTH_CLIENTID];
    [dict setValue:_refreshToken forKey:LIVE_AUTH_REFRESH_TOKEN];
    NSString *result = [LiveAuthHelper encodedQueryParametersForDictionary:dict];
    return result;
}

@end
