/* Copyright (c) 1011 Sven Weidauer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */


#import "OAuthMultiDictionary.h"
#import "NSString+URLEncoding.h"

@implementation OAuthMultiDictionary


- (NSString *) description;
{
    return [storage description];
}

+ (id)dictionary;
{
    return [[[self alloc] init] autorelease];
}

- (void) dealloc;
{
    [storage release];
    [super dealloc];
}

- (void) addObject: (id) object forKey: (id) key;
{
    [self addObjects: [NSArray arrayWithObject: object] forKey: key];
}

- (NSArray *) objectsForKey: (id) key;
{
    return [storage objectForKey: key];
}

- (void) removeObjectsForKey: (id) key;
{
    [storage removeObjectForKey: key];
}

- (void) addObjectsFromMultiDictionary: (OAuthMultiDictionary *)other;
{
    for (id key in [other allKeys]) {
        [self addObjects: [other objectsForKey: key] forKey: key];
    }
}

- (void) addObjectsFromDictionary: (NSDictionary *)other;
{
    for (id key in other) {
        [self addObject: [other objectForKey: key] forKey: key];
    }
}

- (NSArray *) allKeys;
{
    return [storage allKeys];
}

- (void) addObjects: (NSArray *) objects forKey: (id) key;
{
    if (storage == nil) {
        storage = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableArray *list = [storage objectForKey: key];
    if (list == nil) {
        list = [objects mutableCopy];
        [storage setObject: list forKey: key];
        [list release];
    } else {
        [list addObjectsFromArray: objects];
    }
}


- initWithQueryString: (NSString *) query;
{
    if ((self = [super init]) == nil) return nil;
    
    if (query == nil) return self;
    
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@"&="];
    
    NSScanner *scanner = [NSScanner scannerWithString: query];
    [scanner setCharactersToBeSkipped: nil];
    [scanner setCaseSensitive: NO];
    
    while (![scanner isAtEnd]) {
        NSString *key = nil;
        [scanner scanUpToCharactersFromSet: separators intoString: &key];
        key = [key URLDecodedString];
        
        NSString *value = @"";
        
        if ([scanner scanString: @"=" intoString: NULL]) {
            [scanner scanUpToString: @"&" intoString: &value];
            value = [value URLDecodedString];
        }
        
        [scanner scanString: @"&" intoString: NULL];
        
        [self addObject: value forKey: key];
    }
    
    return self;
}

+ dictionaryWithQueryString: (NSString *) queryString;
{
    return [[[self alloc] initWithQueryString: queryString] autorelease];
}

- (id) objectForKey: (id) key;
{
    return [[self objectsForKey: key] objectAtIndex: 0];
}

@end
