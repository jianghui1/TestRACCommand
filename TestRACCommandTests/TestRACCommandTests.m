//
//  TestRACCommandTests.m
//  TestRACCommandTests
//
//  Created by ys on 2018/9/12.
//  Copyright © 2018年 ys. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>

@interface TestRACCommandTests : XCTestCase

@end

@implementation TestRACCommandTests

- (void)test_RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey
{
    RACSignal *enabledSignal = [RACSignal return:@(YES)];
    RACSignal *signal = [RACSignal return:@"hehe"];
    RACCommand *command = [[RACCommand alloc] initWithEnabled:enabledSignal signalBlock:^RACSignal *(id input) {
        return signal;
    }];
    
    [[command execute:nil] subscribeNext:^(id x) {
        NSLog(@"111 -next -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- %@", x);
    } error:^(NSError *error) {
        NSLog(@"111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- %@", error);
    }];
    
    // 打印日志
    /*
     2018-10-11 17:40:00.934158+0800 TestRACCommand[96786:660968] 111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey -- Error Domain=RACCommandErrorDomain Code=1 "The command is disabled and cannot be executed" UserInfo={RACUnderlyingCommandErrorKey=<RACCommand: 0x600000062620>, NSLocalizedDescription=The command is disabled and cannot be executed}
     */
}

- (void)test_RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1
{
    RACSignal *enabledSignal = [RACSignal return:@(YES)];
    RACSignal *signal = [RACSignal error:[NSError errorWithDomain:@"test" code:1 userInfo:@{@"key" : @"value"}]];
    RACCommand *command = [[RACCommand alloc] initWithEnabled:enabledSignal signalBlock:^RACSignal *(id input) {
        return signal;
    }];
    
    [[command execute:nil] subscribeNext:^(id x) {
        NSLog(@"111 -next -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- %@", x);
    } error:^(NSError *error) {
        NSLog(@"111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- %@", error);
    }];
    
    // 打印日志
    /*
     2018-10-11 17:47:51.230763+0800 TestRACCommand[96875:664284] 111 -error -- RACCommandErrorDomain_RACCommandErrorNotEnabled_RACUnderlyingCommandErrorKey1 -- Error Domain=test Code=1 "(null)" UserInfo={key=value}
     */
}

- (void)test_executionSignals
{
    RACSignal *signal0 = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACSignal *signal2 = [RACSignal return:@(2)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal0;
                break;
            case 1:
                return signal1;
                break;
            case 2:
                return signal2;
                break;
                
            default:
                break;
        }
        return nil;
    }];
    command.allowsConcurrentExecution = YES;
    
    RACSignal *eS0 = [command execute:@(0)];
    [eS0 subscribeNext:^(id x) {
        NSLog(@"executionSignals -- eS0 -- %@", x);
    }];
    
    [command.executionSignals subscribeNext:^(id x) {
        NSLog(@"executionSignals -- executionSignals -- %@", x);
        if ([x isKindOfClass:[RACSignal class]]) { // 注意，这里由于`command`内部的处理，直接比较信号是不相等的，但是通过c输出信号值可以看出信号x等效相等。
            RACSignal *signal = x;
            [signal subscribeNext:^(id y) {
                NSLog(@"executionSignals -- executionSignals -- signal -- %@", y);
            }];
        }
    }];
    
    RACSignal *eS1 = [command execute:@(1)];
    [eS1 subscribeNext:^(id x) {
        NSLog(@"executionSignals -- eS1 -- %@", x);
    }];
    
    RACSignal *eS2 = [command execute:@(2)];
    [eS2 subscribeNext:^(id x) {
        NSLog(@"executionSignals -- eS2 -- %@", x);
    }];
    
    // 打印日志
    /*
     2018-10-12 21:06:56.734721+0800 TestRACCommand[57934:1089988] executionSignals -- eS0 -- 0
     2018-10-12 21:06:56.735070+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- <RACDynamicSignal: 0x6000038e2900> name:
     2018-10-12 21:06:56.735293+0800 TestRACCommand[57934:1089988] executionSignals -- eS1 -- 1
     2018-10-12 21:06:56.735414+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- signal -- 1
     2018-10-12 21:06:56.735828+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- <RACDynamicSignal: 0x6000038abac0> name:
     2018-10-12 21:06:56.736155+0800 TestRACCommand[57934:1089988] executionSignals -- eS2 -- 2
     2018-10-12 21:06:56.736337+0800 TestRACCommand[57934:1089988] executionSignals -- executionSignals -- signal -- 2
     */
}

- (void)test_executionSignals1
{
    RACSignal *signal0 = [RACSignal error:[NSError errorWithDomain:@"executionSignals1" code:0 userInfo:nil]];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return signal0;
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.executionSignals subscribeNext:^(id x) {
        NSLog(@"executionSignals -- executionSignals -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    RACSignal *eS0 = [command execute:@(0)];
    [eS0 subscribeNext:^(id x) {
        NSLog(@"executionSignals -- eS0 -- %@", x);
    }];
    
    // 打印日志
    /*
     2018-10-12 21:11:04.161131+0800 TestRACCommand[58045:1091953] executionSignals -- executionSignals -- <RACDynamicSignal: 0x600003c34d40> name:  -- <NSThread: 0x600002962840>{number = 1, name = main}
     */
}

- (void)test_executionSignals2
{
    RACSignal *signal0 = [RACSignal error:[NSError errorWithDomain:@"executionSignals1" code:0 userInfo:nil]];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return signal0;
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.errors subscribeNext:^(id x) {
        NSLog(@"executionSignals -- errors -- %@", x);
    }];
    
    RACSignal *eS0 = [command execute:@(0)];
    [eS0 subscribeNext:^(id x) {
        NSLog(@"executionSignals -- eS0 -- %@", x);
    } error:^(NSError *error) {
        NSLog(@"executionSignals -- eS0 -- error -- %@", error);
    }];
    
    [[eS0 materialize] subscribeNext:^(id x) {
        NSLog(@"executionSignals -- materialize -- %@", x);
    }];
    
    // 打印日志
    /*
     2018-10-12 21:18:06.690660+0800 TestRACCommand[58170:1096115] executionSignals -- eS0 -- error -- Error Domain=executionSignals1 Code=0 "(null)"
     2018-10-12 21:18:06.691228+0800 TestRACCommand[58170:1096115] executionSignals -- materialize -- <RACEvent: 0x6000014d5700>{ error = Error Domain=executionSignals1 Code=0 "(null)" }
     2018-10-12 21:18:06.691695+0800 TestRACCommand[58170:1096115] executionSignals -- errors -- Error Domain=executionSignals1 Code=0 "(null)"
     */
}

- (void)test_executing
{
    RACSignal *signal0 = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal0;
                break;
                case 1:
                return signal1;
                
            default:
                break;
        }
        return nil;
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.executing subscribeNext:^(id x) {
        NSLog(@"executing -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"executing -- 1 - %@", x);
    } completed:^{
        NSLog(@"executing -- 1 - completed");
    }];
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"executing -- 0 - %@", x);
    } completed:^{
        NSLog(@"executing -- 0 - completed");
    }];

    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-10-15 18:36:30.916392+0800 TestRACCommand[97357:1502488] executing -- 0 -- <NSThread: 0x600002419e00>{number = 1, name = main}
     2018-10-15 18:36:30.921302+0800 TestRACCommand[97357:1502488] executing -- 1 -- <NSThread: 0x600002419e00>{number = 1, name = main}
     2018-10-15 18:36:30.921563+0800 TestRACCommand[97357:1502488] executing -- 1 - 1
     2018-10-15 18:36:30.922202+0800 TestRACCommand[97357:1502488] executing -- 1 - completed
     2018-10-15 18:36:30.922647+0800 TestRACCommand[97357:1502488] executing -- 0 - 0
     2018-10-15 18:36:30.923200+0800 TestRACCommand[97357:1502488] executing -- 0 - completed
     2018-10-15 18:36:30.923489+0800 TestRACCommand[97357:1502488] executing -- 0 -- <NSThread: 0x600002419e00>{number = 1, name = main}
     */
}

- (void)test_enabled
{
    RACSignal *signal0 = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal0;
                break;
            case 1:
                return signal1;
                
            default:
                break;
        }
        return nil;
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.enabled subscribeNext:^(id x) {
        NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 1 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 1 - completed");
    }];
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 0 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 0 - completed");
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-10-15 18:50:55.877550+0800 TestRACCommand[97614:1510198] executing -- 0 -- <NSThread: 0x600003176d00>{number = 1, name = main}
     2018-10-15 18:50:55.881961+0800 TestRACCommand[97614:1510198] executing -- 1 -- <NSThread: 0x600003176d00>{number = 1, name = main}
     2018-10-15 18:50:55.882613+0800 TestRACCommand[97614:1510198] executing -- 1 - 1
     2018-10-15 18:50:55.883467+0800 TestRACCommand[97614:1510198] executing -- 1 - completed
     2018-10-15 18:50:55.883662+0800 TestRACCommand[97614:1510198] executing -- 0 - 0
     2018-10-15 18:50:55.884038+0800 TestRACCommand[97614:1510198] executing -- 0 - completed
     2018-10-15 18:50:55.884260+0800 TestRACCommand[97614:1510198] executing -- 0 -- <NSThread: 0x600003176d00>{number = 1, name = main}
     */
}

- (void)test_enabled1
{
    RACSignal *signal0 = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithEnabled:[RACSignal return:@(NO)] signalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal0;
                break;
            case 1:
                return signal1;
                
            default:
                break;
        }
        return nil;
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.enabled subscribeNext:^(id x) {
        NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 1 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 1 - completed");
    }];
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 0 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 0 - completed");
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-10-15 18:56:16.271611+0800 TestRACCommand[97703:1513263] enabled -- 0 -- <NSThread: 0x600001ae1500>{number = 1, name = main}
     */
}

- (void)test_enabled2
{
    RACSignal *signal0 = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithEnabled:[RACSignal return:@(YES)] signalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal0;
                break;
            case 1:
                return signal1;
                
            default:
                break;
        }
        return nil;
    }];
    command.allowsConcurrentExecution = NO;
    
    [command.enabled subscribeNext:^(id x) {
        NSLog(@"enabled -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 1 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 1 - completed");
    }];
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"enabled -- 0 - %@", x);
    } completed:^{
        NSLog(@"enabled -- 0 - completed");
    }];
    
    [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
    
    // 打印日志
    /*
     2018-10-15 18:57:15.525766+0800 TestRACCommand[97741:1514378] enabled -- 1 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
     2018-10-15 18:57:15.530452+0800 TestRACCommand[97741:1514378] enabled -- 0 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
     2018-10-15 18:57:15.530711+0800 TestRACCommand[97741:1514378] enabled -- 1 - 1
     2018-10-15 18:57:15.531299+0800 TestRACCommand[97741:1514378] enabled -- 1 - completed
     2018-10-15 18:57:15.531506+0800 TestRACCommand[97741:1514378] enabled -- 1 -- <NSThread: 0x600001f7e900>{number = 1, name = main}
     */
}

- (void)test_errors
{
    RACSignal *error = [RACSignal error:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{}]];
    RACSignal *error1 = [RACSignal error:[NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:@{}]];
    RACSignal *signal = [RACSignal return:@(2)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return error;
                break;
                
                case 1:
                return error1;
                break;
                
                case 2:
                return signal;
                break;
            default:
                return nil;
                break;
        }
    }];
    command.allowsConcurrentExecution = YES;
    
    [command.errors subscribeNext:^(id x) {
        NSLog(@"todo -- %@ -- %@", x, [NSThread currentThread]);
    }];
    
    [command execute:@(0)];
    [command execute:@(2)];
    [command execute:@(1)];
    
    // 打印日志：
    /*
     2018-10-22 17:34:30.441865+0800 TestRACCommand[52256:749872] todo -- Error Domain=NSURLErrorDomain Code=0 "(null)" -- <NSThread: 0x6000020428c0>{number = 1, name = main}
     2018-10-22 17:34:30.442127+0800 TestRACCommand[52256:749872] todo -- Error Domain=NSURLErrorDomain Code=1 "(null)" -- <NSThread: 0x6000020428c0>{number = 1, name = main}
     */
}

- (void)test_allowsConcurrentExecution
{
    RACSignal *signal = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal;
                break;
            case 1:
                return signal1;
                break;
            default:
                return nil;
                break;
        }
    }];
    command.allowsConcurrentExecution = YES;
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"allowsConcurrentExecution -- %@", x);
    }];
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"allowsConcurrentExecution -- %@", x);
    }];
    // 打印日志
    /*
     2018-10-22 17:47:43.134296+0800 TestRACCommand[52411:755212] allowsConcurrentExecution -- 0
     2018-10-22 17:47:43.134610+0800 TestRACCommand[52411:755212] allowsConcurrentExecution -- 1
     */
}

- (void)test_allowsConcurrentExecution1
{
    RACSignal *signal = [RACSignal return:@(0)];
    RACSignal *signal1 = [RACSignal return:@(1)];
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        switch ([input intValue]) {
            case 0:
                return signal;
                break;
            case 1:
                return signal1;
                break;
            default:
                return nil;
                break;
        }
    }];
    command.allowsConcurrentExecution = NO;
    
    [[command execute:@(0)] subscribeNext:^(id x) {
        NSLog(@"allowsConcurrentExecution1 -- %@", x);
    }];
    [[command execute:@(1)] subscribeNext:^(id x) {
        NSLog(@"allowsConcurrentExecution1 -- %@", x);
    }];
    // 打印日志
    /*
    2018-10-22 17:48:16.669158+0800 TestRACCommand[52427:755785] allowsConcurrentExecution1 -- 0
     */
}

@end
