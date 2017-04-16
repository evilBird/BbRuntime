//
//  BbRuntimeDelegate.m
//  Pods
//
//  Created by Travis Henspeter on 2/26/16.
//
//

#import "BbRuntimeDelegate.h"
#import "BbRuntimeImpBlock.h"
#import "BbRuntimeLookup.h"
#import "NSInvocation+BbRuntime.h"
#import "NSObject+BbRuntime.h"

@interface BbRuntimeDelegate ()

@property (nonatomic,strong) NSSet                  *availableProtocols;
@property (nonatomic,strong) NSMutableSet           *availableSelectors;
@property (nonatomic,strong) NSMutableDictionary    *adoptedProtocols;

@end

@implementation BbRuntimeDelegate

- (void)commonInit
{
    NSArray *protocolNames = [BbRuntimeLookup getProtocolNames];
    
    if ( nil != protocolNames ){
        self.availableProtocols = [NSSet setWithArray:protocolNames];
    }
    
    self.adoptedProtocols = [NSMutableDictionary dictionary];
    self.availableSelectors = [NSMutableSet set];
}

- (BOOL)adoptProtocolWithName:(NSString *)protocolName
{
    if ( nil == protocolName || ![self.availableProtocols containsObject:protocolName] ) {
        return NO;
    }
    
    Protocol *p = objc_getProtocol([protocolName UTF8String]);
    
    if ( [self conformsToProtocol:p] ) {
        return YES;
    }
    
    NSDictionary *protocolSigs = [BbRuntimeLookup getMethodSignaturesForProtocol:protocolName];
    
    if ( nil == protocolSigs ) {
        return NO;
    }
    
    [self.availableSelectors addObjectsFromArray:protocolSigs.allKeys];
    self.adoptedProtocols[protocolName] = protocolSigs;
    
    return YES;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    NSString *protocolName = NSStringFromProtocol(aProtocol);
    NSSet *adoptedProtocolSet = [NSSet setWithArray:self.adoptedProtocols.allKeys];
    return [adoptedProtocolSet containsObject:protocolName];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSString *selectorName = NSStringFromSelector(aSelector);
    BOOL result = [self.availableSelectors containsObject:selectorName];
    return result;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *selectorName = NSStringFromSelector(aSelector);
    NSArray *adoptedProtocolNames = self.adoptedProtocols.allKeys;
    NSMethodSignature *result = nil;
    for (NSString *protocolName in adoptedProtocolNames) {
        NSDictionary *methodSigDictionary = self.adoptedProtocols[protocolName];
        NSArray *selectorNames = methodSigDictionary.allKeys;
        NSSet *selectorNameSet = [NSSet setWithArray:selectorNames];
        if ( [selectorNameSet containsObject:selectorName] ) {
            result = methodSigDictionary[selectorName];
            break;
        }
    }
    
    return result;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if (self.forwardingBlock) {
        typedef void (^MyInvocationBlock)(NSInvocation *myInvocation);
        MyInvocationBlock myInvocationBlock = [_forwardingBlock copy];
        myInvocationBlock(anInvocation);
    }
}


@end
