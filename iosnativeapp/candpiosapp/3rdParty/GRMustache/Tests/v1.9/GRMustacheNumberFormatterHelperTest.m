// The MIT License
// 
// Copyright (c) 2012 Gwendal Roué
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GRMustacheNumberFormatterHelperTest.h"
#import "GRMustacheUtils.h"

@implementation GRMustacheNumberFormatterHelperTest

- (void)testNumberFormatting
{
    NSString *templateString = @"{{#format}}{{value}}{{/format}}";
    GRMustacheTemplate *template = [GRMustacheTemplate parseString:templateString error:NULL];
    
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    numberFormatter.numberStyle = kCFNumberFormatterScientificStyle;
    NSDictionary *helper = [NSDictionary dictionaryWithObject:[GRMustacheNumberFormatterHelper helperWithNumberFormatter:numberFormatter] forKey:@"format"];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.5] forKey:@"value"];
    NSString *result = [template renderObjects:helper, data, nil];
    STAssertEqualObjects(result, @"5E-1", nil);
}

- (void)testNumberFormattingFailsInSubSection
{
    NSString *templateString = @"{{#format}}{{#object}}{{value}}{{/object}}{{/format}}";
    GRMustacheTemplate *template = [GRMustacheTemplate parseString:templateString error:NULL];
    
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    numberFormatter.numberStyle = kCFNumberFormatterScientificStyle;
    NSDictionary *helper = [NSDictionary dictionaryWithObject:[GRMustacheNumberFormatterHelper helperWithNumberFormatter:numberFormatter] forKey:@"format"];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.5] forKey:@"value"] forKey:@"object"];
    NSString *result = [template renderObjects:helper, data, nil];
    STAssertEqualObjects(result, @"0.5", nil);
}

- (void)testNumberFormattingFailsWithKeyPaths
{
    NSString *templateString = @"{{#format}}{{object.value}}{{/format}}";
    GRMustacheTemplate *template = [GRMustacheTemplate parseString:templateString error:NULL];
    
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    numberFormatter.numberStyle = kCFNumberFormatterScientificStyle;
    NSDictionary *helper = [NSDictionary dictionaryWithObject:[GRMustacheNumberFormatterHelper helperWithNumberFormatter:numberFormatter] forKey:@"format"];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.5] forKey:@"value"] forKey:@"object"];
    NSString *result = [template renderObjects:helper, data, nil];
    STAssertEqualObjects(result, @"0.5", nil);
}

- (void)testBooleansAreNotAffected
{
    NSString *templateString = @"{{#format}}{{value}}{{/format}}";
    GRMustacheTemplate *template = [GRMustacheTemplate parseString:templateString error:NULL];
    
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    numberFormatter.numberStyle = kCFNumberFormatterScientificStyle;
    NSDictionary *helper = [NSDictionary dictionaryWithObject:[GRMustacheNumberFormatterHelper helperWithNumberFormatter:numberFormatter] forKey:@"format"];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"value"];
    NSString *result = [template renderObjects:helper, data, nil];
    STAssertEqualObjects(result, @"1", nil);
    
    data = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"value"];
    result = [template renderObjects:helper, data, nil];
    STAssertEqualObjects(result, @"", nil);
}

@end
