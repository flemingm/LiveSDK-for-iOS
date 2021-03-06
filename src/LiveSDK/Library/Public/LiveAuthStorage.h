//
//  LiveAuthStorage.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
   A utility class to handle auth information persistency.
 */
@interface LiveAuthStorage : NSObject
{
@private
    NSString *_clientId;
    NSString *_refreshToken;
}

@property (nonatomic, retain) NSString *refreshToken;

+ (NSString *) keychainItemName;

+ (void) setKeychainItemName:(NSString *)keychainItemName;

- (id) initWithClientId:(NSString *)clientId;

@end
