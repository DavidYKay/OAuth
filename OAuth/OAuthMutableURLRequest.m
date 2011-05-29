/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */


#import "OAuthMutableURLRequest.h"
#import "OAuthMultiDictionary.h"
#import "NSString+URLEncoding.h"
#import "NSData+Base64.h"

#import <CommonCrypto/CommonHMAC.h>

@interface OAuthMutableURLRequest ()

- (OAuthMultiDictionary *) collectParameters;

@end


@implementation OAuthMutableURLRequest

@synthesize consumerSecret = oauthConsumerSecret;
@synthesize tokenSecret = oauthTokenSecret;

- (NSString *) signatureBaseString;
{
    OAuthMultiDictionary *parameters = [self collectParameters];
    [parameters removeObjectsForKey: @"oauth_signature"];
    [parameters removeObjectsForKey: @"oauth_realm"];
    
    NSMutableArray *parameterStrings = [NSMutableArray array];
    for (NSString *key in [parameters allKeys]) {
        for (NSString *value in [parameters objectsForKey: key]) {
            [parameterStrings addObject: [NSString stringWithFormat: @"%@=%@", [key URLEncodedString], [value URLEncodedString]]];
        }
    }
    [parameterStrings sortUsingSelector: @selector( compare: )];
    NSString *paramString = [[parameterStrings componentsJoinedByString: @"&"] URLEncodedString];
    
    NSString *baseURL = [[self URL] absoluteString];
    NSUInteger queryStart = [baseURL rangeOfString: @"?"].location;
    if (queryStart != NSNotFound) baseURL = [baseURL substringToIndex: queryStart];
    baseURL = [baseURL URLEncodedString];
    
    NSString *method = [[self HTTPMethod] URLEncodedString];
    
    return [NSString stringWithFormat: @"%@&%@&%@", method, baseURL, paramString];
}


static inline NSData *HMAC_SHA1( NSData *key, NSData *value )
{
    char signature[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac( kCCHmacAlgSHA1, [key bytes], [key length], [value bytes], [value length], signature );
    
    return [NSData dataWithBytes: signature length: CC_SHA1_DIGEST_LENGTH];
}

- (void) sign;
{
    NSString *nonce = [[NSProcessInfo processInfo] globallyUniqueString];
    [self setValue: nonce forOAuthParameter: @"oauth_nonce"];

    unsigned long time = (unsigned long)[[NSDate date] timeIntervalSince1970];
    [self setValue: [NSString stringWithFormat: @"%lu", time] forOAuthParameter: @"oauth_timestamp"];

    [self setValue: @"HMAC-SHA1" forOAuthParameter: @"oauth_signature_method"];

    NSAssert( oauthConsumerSecret != nil, @"Consumer secret required for signing OAuth request" );

    NSString *tokenKey  = oauthTokenSecret;
    if (tokenKey == nil) tokenKey = @"";

    NSData *key = [[NSString stringWithFormat: @"%@&%@", oauthConsumerSecret, tokenKey] dataUsingEncoding: NSASCIIStringEncoding];
    NSData *baseString = [[self signatureBaseString] dataUsingEncoding: NSASCIIStringEncoding];
    
    NSString *signature = [HMAC_SHA1( key,  baseString ) base64EncodingWithLineLength: 0];
    [self setValue: signature forOAuthParameter: @"oauth_signature"];
    
    NSMutableArray *authParameters = [NSMutableArray arrayWithCapacity: [oauthParameters count]];
    NSString *realm = [oauthParameters objectForKey: @"oauth_realm"];
    if (realm != nil) {
        [authParameters addObject: [NSString stringWithFormat: @"realm=\"%@\"", realm]];
    }
         
    for (NSString *key in oauthParameters) {
        if ([key isEqualToString: @"oauth_realm"]) continue;
        [authParameters addObject: [NSString stringWithFormat: @"%@=\"%@\"", key, [[oauthParameters objectForKey: key] URLEncodedString]]];
    }
    
    NSString *header = [NSString stringWithFormat:@"OAuth %@", [authParameters componentsJoinedByString: @", "]];
    [self setValue: header forHTTPHeaderField: @"Authorization"];
}

- (void) setValue: (NSString *) value forOAuthParameter: (NSString *) parameterName;
{
    if (oauthParameters == nil) {
        oauthParameters = [[NSMutableDictionary alloc] init];
    }
    [oauthParameters setValue: [[value copy] autorelease] forKey: parameterName];
}

- (NSString *)valueForOAuthParameter:(NSString *)parameterName;
{
    return [oauthParameters objectForKey: parameterName];
}

- (OAuthMultiDictionary *) collectParameters;
{
    OAuthMultiDictionary *result = [OAuthMultiDictionary dictionaryWithQueryString: [[self URL] query]];
    
    [result addObjectsFromDictionary: oauthParameters];
    
    if ([[self HTTPMethod] isEqualToString: @"POST"]) {
        NSString *contentType = [self valueForHTTPHeaderField: @"Content-Type"];
        if ([contentType isEqualToString: @"application/x-www-form-urlencoded"]) {
            NSString *body = [[NSString alloc] initWithData: [self HTTPBody] encoding: NSASCIIStringEncoding];
            [result addObjectsFromMultiDictionary: [OAuthMultiDictionary dictionaryWithQueryString: body]];
            [body release];
        }
    }
    
    return result;
}

- (NSString *) token;
{
    return [oauthParameters objectForKey: @"oauth_token"];
}

- (void) setToken: (NSString *) token;
{
    [self setValue: token forOAuthParameter: @"oauth_token"];
}

- (void) setToken: (NSString *) token secret: (NSString *) secret;
{
    [self setValue: token forOAuthParameter: @"oauth_token"];
    [self setTokenSecret: secret];
}

- (NSString *) consumerKey;
{
    return [oauthParameters objectForKey: @"oauth_consumer_key"];
}

- (void) setConsumerKey: (NSString *) key;
{
    [self setValue: key forOAuthParameter: @"oauth_consumer_key"];
}

- (void) setConsumerKey: (NSString *) key secret:  (NSString *) secret;
{
    [self setValue: key forOAuthParameter: @"oauth_consumer_key"];
    [self setConsumerSecret: secret];
}

- (void) dealloc;
{
    [oauthTokenSecret release];
    [oauthParameters release];
    [oauthConsumerSecret release];
    
    [super dealloc];
}

@end
