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

#import "GRMustacheTemplate_v1_4_Test.h"


@implementation GRMustacheTemplate_v1_4_Test

- (void)testRenderFromFile
{
    NSString *path = [[self.testBundle resourcePath] stringByAppendingPathComponent:@"passenger.conf"];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"example.com", @"server",
                             @"/var/www/example.com", @"deploy_to",
                             @"production", @"stage",
                             nil];
    NSString *result = [GRMustacheTemplate renderObject:context fromContentsOfFile:path error:nil];
    STAssertEqualObjects(result, @"<VirtualHost *>\n  ServerName example.com\n  DocumentRoot /var/www/example.com\n  RailsEnv production\n</VirtualHost>\n", nil);
}

- (void)testParseFromFileReportsError
{
    NSString *path = [[self.testBundle resourcePath] stringByAppendingPathComponent:@"syntax_error.conf"];
    NSError *error = nil;
    GRMustacheTemplate *template = [GRMustacheTemplate parseContentsOfFile:path error:&error];
    STAssertNil(template, nil);
    STAssertEquals(error.code, (NSInteger)GRMustacheErrorCodeParseError, nil);
}

- (void)testRenderFromFileReportsError
{
    NSString *path = [[self.testBundle resourcePath] stringByAppendingPathComponent:@"syntax_error.conf"];
    NSError *error = nil;
    NSString *result = [GRMustacheTemplate renderObject:nil fromContentsOfFile:path error:&error];
    STAssertNil(result, nil);
    STAssertEquals(error.code, (NSInteger)GRMustacheErrorCodeParseError, nil);
}

@end
