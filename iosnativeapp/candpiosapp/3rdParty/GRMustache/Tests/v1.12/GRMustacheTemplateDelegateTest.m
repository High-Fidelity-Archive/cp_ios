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

#import "GRMustacheTemplateDelegateTest.h"

@interface GRMustacheTemplateDelegateAssistant : NSObject
@property (nonatomic) BOOL boolProperty;
@end

@implementation GRMustacheTemplateDelegateAssistant
@synthesize boolProperty;
@end

@interface GRMustacheTemplateRecorder : NSObject<GRMustacheTemplateDelegate>
@property (nonatomic) NSUInteger templateWillRenderCount;
@property (nonatomic) NSUInteger templateDidRenderCount;
@property (nonatomic) NSUInteger willRenderReturnValueOfInvocationCount;
@property (nonatomic) NSUInteger didRenderReturnValueOfInvocationCount;
@property (nonatomic) NSUInteger nilReturnValueCount;
@property (nonatomic) NSUInteger booleanReturnValueCount;
@property (nonatomic, retain) NSString *lastUsedKey;
@end

@implementation GRMustacheTemplateRecorder
@synthesize templateWillRenderCount=_templateWillRenderCount;
@synthesize templateDidRenderCount=_templateDidRenderCount;
@synthesize willRenderReturnValueOfInvocationCount=_willRenderReturnValueOfInvocationCount;
@synthesize didRenderReturnValueOfInvocationCount=_didRenderReturnValueOfInvocationCount;
@synthesize nilReturnValueCount=_nilReturnValueCount;
@synthesize booleanReturnValueCount=_booleanReturnValueCount;
@synthesize lastUsedKey=_lastUsedKey;

- (void)dealloc
{
    self.lastUsedKey = nil;
    [super dealloc];
}

- (void)templateWillRender:(GRMustacheTemplate *)template
{
    self.templateWillRenderCount += 1;
}

- (void)templateDidRender:(GRMustacheTemplate *)template
{
    self.templateDidRenderCount += 1;
}

- (void)template:(GRMustacheTemplate *)template willRenderReturnValueOfInvocation:(GRMustacheInvocation *)invocation
{
    self.willRenderReturnValueOfInvocationCount += 1;
    self.lastUsedKey = invocation.key;
    if (invocation.returnValue) {
        if ((void *)invocation.returnValue == (void *)kCFBooleanTrue || (void *)invocation.returnValue == (void *)kCFBooleanFalse) {
            self.booleanReturnValueCount += 1;
        } else if ([invocation.returnValue isKindOfClass:[NSString class]]) {
            invocation.returnValue = [[invocation.returnValue description] uppercaseString];
        }
    } else {
        self.nilReturnValueCount += 1;
    }
}

- (void)template:(GRMustacheTemplate *)template didRenderReturnValueOfInvocation:(GRMustacheInvocation *)invocation
{
    self.didRenderReturnValueOfInvocationCount += 1;
}

@end

@implementation GRMustacheTemplateDelegateTest

- (void)testTemplateWillRender
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.templateWillRenderCount, (NSUInteger)1, @"");
}

- (void)testTemplateDidRender
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.templateDidRenderCount, (NSUInteger)1, @"");
}

- (void)testTemplateWillRenderIsNotCalledForPartial
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplateLoader *loader = [GRMustacheTemplateLoader templateLoaderWithBundle:self.testBundle];
    GRMustacheTemplate *template = [loader templateFromString:@"{{>foo_bar}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.templateWillRenderCount, (NSUInteger)1, @"");
}

- (void)testTemplateDidRenderIsNotCalledForPartial
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplateLoader *loader = [GRMustacheTemplateLoader templateLoaderWithBundle:self.testBundle];
    GRMustacheTemplate *template = [loader templateFromString:@"{{>foo_bar}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.templateDidRenderCount, (NSUInteger)1, @"");
}

- (void)testWillRenderReturnValueOfInvocationWithText
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"---" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.willRenderReturnValueOfInvocationCount, (NSUInteger)0, @"");
}

- (void)testDidRenderReturnValueOfInvocationWithText
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"---" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.didRenderReturnValueOfInvocationCount, (NSUInteger)0, @"");
}

- (void)testWillRenderReturnValueOfInvocationWithVariable
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}{{bar}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.willRenderReturnValueOfInvocationCount, (NSUInteger)2, @"");
}

- (void)testDidRenderReturnValueOfInvocationWithVariable
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}{{bar}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.didRenderReturnValueOfInvocationCount, (NSUInteger)2, @"");
}

- (void)testWillRenderReturnValueOfInvocationWithUnrenderedSection
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#foo}}{{bar}}{{/foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.willRenderReturnValueOfInvocationCount, (NSUInteger)1, @"");
}

- (void)testDidRenderReturnValueOfInvocationWithUnrenderedSection
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#foo}}{{bar}}{{/foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.didRenderReturnValueOfInvocationCount, (NSUInteger)1, @"");
}

- (void)testWillRenderReturnValueOfInvocationWithRenderedSectionAndVariable
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{^foo}}{{bar}}{{/foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.willRenderReturnValueOfInvocationCount, (NSUInteger)2, @"");
}

- (void)testDidRenderReturnValueOfInvocationWithRenderedSectionAndVariable
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{^foo}}{{bar}}{{/foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEquals(recorder.didRenderReturnValueOfInvocationCount, (NSUInteger)2, @"");
}

- (void)testDelegateCanReadInvocationReturnValue
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}{{bar}}" error:NULL];
    template.delegate = recorder;
    [template renderObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"foo"]];
    STAssertEquals(recorder.nilReturnValueCount, (NSUInteger)1, @"");
}

- (void)testDelegateCanReadInvocationReturnValueFromBooleanProperties
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{#1}}{{boolProperty}}{{/1}}{{#2}}{{boolProperty}}{{/2}}" error:NULL];
    template.delegate = recorder;
    GRMustacheTemplateDelegateAssistant *assistant1 = [[[GRMustacheTemplateDelegateAssistant alloc] init] autorelease];
    GRMustacheTemplateDelegateAssistant *assistant2 = [[[GRMustacheTemplateDelegateAssistant alloc] init] autorelease];
    assistant1.boolProperty = YES;
    assistant2.boolProperty = NO;
    [template renderObject:[NSDictionary dictionaryWithObjectsAndKeys:assistant1, @"1", assistant2, @"2", nil]];
    STAssertEquals(recorder.booleanReturnValueCount, (NSUInteger)2, @"");
}

- (void)testDelegateCanReadInvocationReturnValueFromKeyPath
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{1.boolProperty}}{{2.boolProperty}}" error:NULL];
    template.delegate = recorder;
    GRMustacheTemplateDelegateAssistant *assistant1 = [[[GRMustacheTemplateDelegateAssistant alloc] init] autorelease];
    GRMustacheTemplateDelegateAssistant *assistant2 = [[[GRMustacheTemplateDelegateAssistant alloc] init] autorelease];
    assistant1.boolProperty = YES;
    assistant2.boolProperty = NO;
    [template renderObject:[NSDictionary dictionaryWithObjectsAndKeys:assistant1, @"1", assistant2, @"2", nil]];
    STAssertEquals(recorder.booleanReturnValueCount, (NSUInteger)2, @"");
}

- (void)testDelegateCanReadInvocationKey
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}" error:NULL];
    template.delegate = recorder;
    [template render];
    STAssertEqualObjects(recorder.lastUsedKey, @"foo", @"");
}

- (void)testDelegateCanReadInvocationKeyFromKeyPath
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo.bar.baz}}" error:NULL];
    template.delegate = recorder;
    [template renderObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"foo"]];
    STAssertEqualObjects(recorder.lastUsedKey, @"bar", @"");
}

- (void)testDelegateCanWriteInvocationReturnValue
{
    GRMustacheTemplateRecorder *recorder = [[[GRMustacheTemplateRecorder alloc] init] autorelease];
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromString:@"{{foo}}" error:NULL];
    template.delegate = recorder;
    NSString *result = [template renderObject:[NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"]];
    STAssertEqualObjects(result, @"BAR", @"");
}

@end
