/**
 * Beijing Sankuai Online Technology Co.,Ltd (Meituan)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
 
QuickSpecBegin(ERActionSpec)

describe(@"ERAction test", ^{
    it(@"has default property values", ^{
        ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
            result.value = param;
        }];
        expect(action.result).to(beEmptyValue());
        expect(action.error).to(beEmptyValue());
        expect(action.enable.value).to(equal(@YES));
        expect(action.executing.value).to(equal(@NO));
    });

    it(@"can be executed and get a result", ^{
        ERAction<NSNumber *, NSNumber *> *action = [[ERAction alloc] initWithBlock:^(NSNumber * _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
            result.value = @(param.integerValue * 10);
        }];
        [action execute:@123];
        expect(action.result.value).to(equal(@1230));
        expect(action.error).to(beEmptyValue());
    });

    it(@"can be executed and return an error", ^{
        NSError *err = [NSError errorWithDomain:@"xx" code:123 userInfo:@{@"reason": @"param is nil"}];
        ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
            if (!param) {
                error.value = err;
            } else {
                result.value = @"succ";
            }
        }];
        [action execute:nil];
        expect(action.result).to(beEmptyValue());
        expect(action.error.value).to(equal(err));
    });

    it(@"can be executed multiple times and saves the last result", ^{
        NSError *err = [NSError errorWithDomain:@"xx" code:123 userInfo:@{@"reason": @"param is nil"}];
        ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error)  {
            if (!param) {
                error.value = err;
            } else {
                result.value = [NSString stringWithFormat:@"p:%@", param];
            }
        }];

        [action.result startListenForTestWithObj:self];
        [action.error startListenForTestWithObj:self];

        dispatch_queue_t q = dispatch_queue_create("com.meituan.er.test.queue", DISPATCH_QUEUE_CONCURRENT);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), q, ^{
            [action execute:@123];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), q, ^{
            [action execute:nil];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), q, ^{
            [action execute:@789];
        });

        
        expect(action.result.value).withTimeout(0.3).toEventually(equal(@"p:789"));
        expect(action.error.value).withTimeout(0.3).toEventually(equal(err));
        expect(action.result).withTimeout(0.3).toEventually(receive(@[@"p:123", @"p:789"]));
        expect(action.error).withTimeout(0.3).toEventually(receive(@[err]));
    });

    it(@"can get a result synchronously", ^{
        ERAction<NSNumber *, NSNumber *> *action = [ERAction actionWithSyncBlock:^id _Nullable(NSNumber *_Nullable param, NSError *__autoreleasing _Nullable * _Nullable returnError) {
            return @(param.integerValue * 2);
        }];
        [action execute:@100];
        expect(action.result.value).to(equal(@200));
        expect(action.error).to(beEmptyValue());
    });

    it(@"can get an error synchronously", ^{
        NSError *err = [NSError errorWithDomain:@"a" code:1 userInfo:@{}];
        ERAction<NSNumber *, NSNumber *> *action = [[ERAction alloc] initWithSyncBlock:^id _Nullable(NSNumber *_Nullable param, NSError *__autoreleasing _Nullable * _Nullable returnError) {
            if (!param) {
                *returnError = err;
                return EZREmpty.empty;
            } else {
                return param;
            }
        }];

        [action execute:nil];
        expect(action.result).to(beEmptyValue());
        expect(action.error.value).to(equal(err));
    });

    it(@"can be released correctly", ^{
        expectCheckTool(^(CheckReleaseTool *checkTool) {
            ERAction *action1 = [ERAction actionWithSyncBlock:^id _Nullable(id _Nullable param, NSError *__autoreleasing _Nullable * _Nullable returnError) {
                return param;
            }];
            ERAction *action2 = [ERAction actionWithBlock:^(id _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                result.mutablify.value = param;
            }];
            [action1 execute:@111];
            [action2 execute:@111];
            [checkTool checkObj:action1];
            [checkTool checkObj:action2];
        }).to(beReleasedCorrectly());

    });

    it(@"will raise an exception if you set the result after the first result/error assignment", ^{
        expectAction(^{
            ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                result.value = @111;
                result.value = @222;
            }];
            [action execute:@123];
        }).to(raiseException().named(ERActionException).reason(ERExceptionReason_UnexpectedResultAssignment));
        
        expectAction(^{
            ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                error.value = [NSError errorWithDomain:@"a" code:1 userInfo:nil];
                result.value = @222;
            }];
            [action execute:@123];
        }).to(raiseException().named(ERActionException).reason(ERExceptionReason_UnexpectedResultAssignment));
    });

    it(@"will raise an exception if you set the error after the first result/error assignment", ^{
        expectAction(^{
            ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                error.value = [NSError errorWithDomain:@"aaa" code:123 userInfo:nil];
                error.value = [NSError errorWithDomain:@"bbb" code:321 userInfo:nil];
            }];
            [action execute:@123];
        }).to(raiseException().named(ERActionException).reason(ERExceptionReason_UnexpectedErrorAssignment));
        
        expectAction(^{
            ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                result.value = param;
                error.value = [NSError errorWithDomain:@"ddd" code:1 userInfo:nil];
            }];
            [action execute:@123];
        }).to(raiseException().named(ERActionException).reason(ERExceptionReason_UnexpectedErrorAssignment));
    });

    it(@"will return an ERActionResult containing the result or the error", ^{
        ERAction *action1 = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
            result.value = param;
        }];
        EZRNode<ERActionResult *> *result1 = [action1 execute:@123];    
        expect(result1.value.value).to(equal(@123));
        expect(result1.value.error).to(beNil());
        expect(@(result1.value.status)).to(equal(@(ERActionResultStatusSuccess)));

        NSError *err = [NSError errorWithDomain:@"aaa" code:111 userInfo:@{}];
        ERAction *action2 = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
            error.value = err;
        }];
        EZRNode<ERActionResult *> *result2 = [action2 execute:nil];
        expect(result2.value.value).to(beNil());
        expect(result2.value.error).to(equal(err));
        expect(@(result2.value.status)).to(equal(@(ERActionResultStatusFailure)));
    });

    context(@"async & multi-thread", ^{
        __block dispatch_queue_t q1 = nil;
        __block dispatch_queue_t q2 = nil;
        beforeEach(^{
            q1 = dispatch_queue_create("com.meituan.er.test.queue1", DISPATCH_QUEUE_CONCURRENT);
            q2 = dispatch_queue_create("com.meituan.er.test.queue2", DISPATCH_QUEUE_CONCURRENT);
        });

        afterEach(^{
            q1 = nil;
            q2 = nil;
        });

        it(@"has correct executing & enable status while executing and after executing", ^{
            ERAction *action = [[ERAction alloc] initWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), q1, ^{
                    result.value = @"slow action finished";
                });
            }];
            dispatch_async(q2, ^{
                [action execute:@111];
            });
            expect(action.enable.value).withTimeout(0.1).toEventually(equal(@NO));
            expect(action.executing.value).withTimeout(0.1).toEventually(equal(@YES));
            
            expect(action.result.value).withTimeout(1).toEventually(equal(@"slow action finished"));
            expect(action.executing.value).withTimeout(1).toEventually(equal(@NO));
            expect(action.enable.value).withTimeout(1).toEventually(equal(@YES));
        });

        it(@"will get an error if you run it concurrently", ^{
            ERAction<NSNumber *, NSNumber *> *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), q1, ^{
                    result.value = param;
                });
            }];
            [action.result startListenForTestWithObj:self];

            dispatch_async(q1, ^{
                [action execute:@3];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), q2, ^{
                EZRNode<ERActionResult<NSNumber *> *> *result = [action execute:@1];
                expect(result).notTo(beEmptyValue());
                expect(result.value.value).to(beNil());
                expect(result.value.error.domain).to(equal(ERErrorDomain));
                expect(result.value.error.code).to(equal(ERErrorCodeExecutingDisabledAction));
            });
            expect(action.error).withTimeout(1).toEventuallyNot(beEmptyValue());
            expect(action.error.value.domain).withTimeout(1).toEventually(equal(ERErrorDomain));
            expect(action.error.value.code).withTimeout(1).toEventually(equal(ERErrorCodeExecutingDisabledAction));
            expect(action.result).withTimeout(1).toEventually(receive(@[@3]));
        });

        it(@"can be executed asynchronously", ^{
            ERAction *action = [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), q1, ^{
                    result.value = @"slow action finished";
                });
            }];
            EZRNode<ERActionResult *> *result = [action execute:@123];
            [action.result startListenForTestWithObj:self];

            expect(result).to(beEmptyValue());
            expect(result).withTimeout(0.3).toEventuallyNot(beEmptyValue());
            expect(result.value.value).withTimeout(0.3).toEventually(equal(@"slow action finished"));
            expect(action.result).to(receive(@[@"slow action finished"]));
        });
        
        it(@"典型的正确逆变场景" ,^{
            ERAction<ChildOfChild *, Father *> *action = [[ERAction alloc] initWithSyncBlock:^ChildOfChild * _Nullable(Father * _Nullable param, NSError *__autoreleasing  _Nullable * _Nullable returnError) {
                ChildOfChild *result = [ChildOfChild new];
                result.a = param.a;
                result.b = param.b;
                result.c = 4;
                return result;
            }];
            ERFamilyOperator *op = [ERFamilyOperator new];
            Child *c = [op operation:action];
            expect(c.c).to(equal(4));
        });
        
        it(@"典型的错误逆变场景。 请注意`[op operation:action]` 编译器给的Warning" ,^{
            dispatch_block_t block = ^{
                ERAction<ChildOfChild *, ChildOfChild *> *action = [[ERAction alloc] initWithSyncBlock:^ChildOfChild * _Nullable(ChildOfChild * _Nullable param, NSError *__autoreleasing  _Nullable * _Nullable returnError) {
                    param.d = 4;
                    return param;
                }];
                ERFamilyOperator *op = [ERFamilyOperator new];
                [op operation:action];
            };
            expectAction(block).to(raiseException().named(@"NSInvalidArgumentException"));
        });
    });
});

QuickSpecEnd
