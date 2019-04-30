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
 
QuickSpecBegin(EZRNodeAction)

describe(@"EZRNode Action test", ^{
    
    context(@"apply", ^{
        it(@"can apply an action", ^{
            EZRNode<NSNumber *> *value = [EZRNode value:@1];
            ERAction<NSNumber *, NSNumber *> *action = [ERAction actionWithBlock:^(NSNumber *_Nullable param, EZRNode<NSNumber *> * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @(param.integerValue * 2);
            }];
            [action.result startListenForTest];
            [value apply:action];
            value.value = @2;
            value.value = @3;
            value.value = @4;
            
            expect(action.result).to(receive(@[@2, @4, @6, @8]));
        });
        
        it(@"can stop apply", ^{
            EZRNode<NSNumber *> *value = [EZRNode value:@1];
            ERAction<NSNumber *, NSNumber *> *action = [ERAction actionWithBlock:^(NSNumber *_Nullable param, EZRNode<NSNumber *> * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @(param.integerValue * 2);
            }];
            [action.result startListenForTest];
            id<ERCancelable> cancelable = [value apply:action];
            value.value = @2;
            value.value = @3;
            [cancelable cancel];
            value.value = @4;
            
            expect(action.result).to(receive(@[@2, @4, @6]));
        });
        
        it(@"can stop listen after action destroyed", ^{
            EZRNode<NSNumber *> *value = [EZRNode value:@1];
            ERAction<NSNumber *, NSNumber *> *action = [[ERAction alloc] initWithBlock:^(NSNumber *_Nullable param, EZRNode<NSNumber *> * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @(param.integerValue * 2);
            }];
            [value apply:action];
            expect(value.hasListener).to(beTruthy());
            action = nil;
            expect(value.hasListener).to(beFalsy());
        });
        
        it(@"can be released correctly", ^{
            void (^check)(CheckReleaseTool *checkTool) = ^(CheckReleaseTool *checkTool) {
                EZRNode<NSNumber *> *value = [EZRNode value:@1];
                ERAction<NSNumber *, NSNumber *> *action = [ERAction actionWithBlock:^(NSNumber *_Nullable param, EZRNode<NSNumber *> * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                    result.value = @(param.integerValue * 2);
                }];
                [value apply:action];
                [checkTool checkObj:value];
                [checkTool checkObj:action];
            };
            expectCheckTool(check).to(beReleasedCorrectly());
        });
    });
});

QuickSpecEnd
