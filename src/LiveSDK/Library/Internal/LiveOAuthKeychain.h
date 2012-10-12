//
//  LiveOAuthKeychain.h
//  LiveSDK
//
//  Created by Superbil on 12/10/12.
//
//

#import <Foundation/Foundation.h>

@interface LiveOAuthKeychain : NSObject

+ (LiveOAuthKeychain *)defaultKeychain;

// OK to pass nil for the error parameter.
- (NSString *)passwordForService:(NSString *)service
                         account:(NSString *)account
                           error:(NSError **)error;

// OK to pass nil for the error parameter.
- (BOOL)removePasswordForService:(NSString *)service
                         account:(NSString *)account
                           error:(NSError **)error;

// OK to pass nil for the error parameter.
//
// accessibility should be one of the constants for kSecAttrAccessible
// such as kSecAttrAccessibleWhenUnlocked
- (BOOL)setPassword:(NSString *)password
         forService:(NSString *)service
      accessibility:(CFTypeRef)accessibility
            account:(NSString *)account
              error:(NSError **)error;

// For unit tests: allow setting a mock object
+ (void)setDefaultKeychain:(LiveOAuthKeychain *)keychain;

@end
