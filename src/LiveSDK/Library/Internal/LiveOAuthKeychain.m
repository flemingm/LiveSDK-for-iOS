//
//  LiveOAuthKeychain.m
//  LiveSDK
//
//  Created by Superbil on 12/10/12.
//
//

#import "LiveOAuthKeychain.h"
#import "LiveConstants.h"

static LiveOAuthKeychain *sLiveOAuthKeychain;

@implementation LiveOAuthKeychain

+ (LiveOAuthKeychain *)defaultKeychain {
    if (sLiveOAuthKeychain == nil) {
        sLiveOAuthKeychain = [[self alloc] init];
    }
    return sLiveOAuthKeychain;
}

// For unit tests: allow setting a mock object
+ (void)setDefaultKeychain:(LiveOAuthKeychain *)keychain {
    if (sLiveOAuthKeychain != keychain) {
        [sLiveOAuthKeychain release];
        sLiveOAuthKeychain = [keychain retain];
    }
}

+ (NSMutableDictionary *)keychainQueryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (id)kSecClassGenericPassword, (id)kSecClass,
                                  @"OAuth", (id)kSecAttrGeneric,
                                  account, (id)kSecAttrAccount,
                                  service, (id)kSecAttrService,
                                  nil];
    return query;
}

- (NSMutableDictionary *)keychainQueryForService:(NSString *)service account:(NSString *)account {
    return [[self class] keychainQueryForService:service account:account];
}

// The Keychain API isn't available on the iPhone simulator in SDKs before 3.0,
// so, on early simulators we use a fake API, that just writes, unencrypted, to
// NSUserDefaults.
#pragma mark - KeyChain Methods

- (NSString *)passwordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    OSStatus status = LIVE_ERROR_AUTH_BAD_ARGUMENTS;
    NSString *result = nil;
    if (0 < [service length] && 0 < [account length]) {
        CFDataRef passwordData = NULL;
        NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
        [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
        [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];

        status = SecItemCopyMatching((CFDictionaryRef)keychainQuery,
                                     (CFTypeRef *)&passwordData);
        if (status == noErr && 0 < [(NSData *)passwordData length]) {
            result = [[[NSString alloc] initWithData:(NSData *)passwordData
                                            encoding:NSUTF8StringEncoding] autorelease];
        }
        if (passwordData != NULL) {
            CFRelease(passwordData);
        }
    }
    if (status != noErr && error != NULL) {
        *error = [NSError errorWithDomain:LIVE_ERROR_AUTH_DOMAIN
                                     code:status
                                 userInfo:nil];
    }
    return result;
}

- (BOOL)removePasswordForService:(NSString *)service account:(NSString *)account error:(NSError **)error {
    OSStatus status = LIVE_ERROR_AUTH_BAD_ARGUMENTS;
    if (0 < [service length] && 0 < [account length]) {
        NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
        status = SecItemDelete((CFDictionaryRef)keychainQuery);
    }
    if (status != noErr && error != NULL) {
        *error = [NSError errorWithDomain:LIVE_ERROR_AUTH_DOMAIN
                                     code:status
                                 userInfo:nil];
    }
    return status == noErr;
}

- (BOOL)setPassword:(NSString *)password
         forService:(NSString *)service
      accessibility:(CFTypeRef)accessibility
            account:(NSString *)account
              error:(NSError **)error {
    OSStatus status = LIVE_ERROR_AUTH_BAD_ARGUMENTS;
    if (0 < [service length] && 0 < [account length]) {
        [self removePasswordForService:service account:account error:nil];
        if (0 < [password length]) {
            NSMutableDictionary *keychainQuery = [self keychainQueryForService:service account:account];
            NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
            [keychainQuery setObject:passwordData forKey:(id)kSecValueData];
            
#if (!TARGET_OS_MAC )
            // ios speific
            if (accessibility != NULL && &kSecAttrAccessible != NULL) {
                [keychainQuery setObject:(id)accessibility
                                  forKey:(id)kSecAttrAccessible];
            }
#endif
            status = SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
        }
    }
    if (status != noErr && error != NULL) {
        *error = [NSError errorWithDomain:LIVE_ERROR_AUTH_DOMAIN
                                     code:status
                                 userInfo:nil];
    }
    return status == noErr;
}

@end

