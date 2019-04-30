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
 
QuickSpecBegin(ERActionOperation)

describe(@"ERActionOperation test", ^{
    context(@"serial", ^{
        it(@"can concatenate two actions into one", ^{
            ERAction<NSNumber *, NSString *> *action1 = [ERAction actionWithBlock:^(NSString * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @(param.doubleValue);
            }];
            ERAction<NSDate *, NSNumber *> *action2 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = [NSDate dateWithTimeIntervalSince1970:param.doubleValue];
            }];

            ERAction<NSDate *, NSString *> *action3 = [action1 actionWithSerialAction:action2];

            [action3 execute:@"1498219579"];

            expect(action3.error).to(beEmptyValue());
            expect(action3.result.value).to(equal([NSDate dateWithTimeIntervalSince1970:1498219579]));
        });
    });

    context(@"concurrent", ^{
        it(@"can create an action from several actions and make them running in parallel", ^{
            ERAction<NSString *, NSNumber *> *action1 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = [NSString stringWithFormat:@"1: %@", param];
            }];
            ERAction<NSString *, NSNumber *> *action2 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = [NSString stringWithFormat:@"2: %@", param];
            }];
            ERAction<NSString *, NSNumber *> *action3 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = [NSString stringWithFormat:@"3: %@", param];
            }];
            
            ERAction<NSArray<NSString *> *, NSArray<NSNumber *> *> *action = [ERAction actionWithConcurrentActions:@[action1, action2, action3]];
            [action execute:@[@100, @200, @300]];
            
            expect(action.result.value).to(equal(ZTuple(@"1: 100", @"2: 200", @"3: 300")));
        });

        it(@"treats nil as an array of NSNull for the action parameter", ^{
            ERAction<NSString *, NSNumber *> *action1 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"A";
            }];
            ERAction<NSString *, NSNumber *> *action2 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"B";
            }];
            ERAction<NSString *, NSNumber *> *action3 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"C";
            }];

            ERAction<NSArray<NSString *> *, NSArray<NSNumber *> *> *action = [ERAction actionWithConcurrentActions:@[action1, action2, action3]];
            [action execute:nil];
            NSArray *result1 = action.result.value;
            expect(action.result.value).to(equal(ZTuple(@"A", @"B", @"C")));

            [action execute:@[NSNull.null, NSNull.null, NSNull.null]];
            NSArray *result2 = action.result.value;
            expect(result2).to(equal(result1));
        });

        it(@"will raise an exception if the parameter is invalid", ^{
            ERAction<NSString *, NSNumber *> *action1 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"A";
            }];
            ERAction<NSString *, NSNumber *> *action2 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"B";
            }];
            ERAction<NSString *, NSNumber *> *action3 = [ERAction actionWithBlock:^(NSNumber * _Nullable param, EZRNode * _Nonnull result, EZRNode<NSError *> * _Nonnull error) {
                result.value = @"C";
            }];

            ERAction<NSArray<NSString *> *, NSArray<NSNumber *> *> *action = [ERAction actionWithConcurrentActions:@[action1, action2, action3]];
            
            expectAction((^{
                [action execute:@[@100, @200, @300, @400]];
            })).to(raiseException().named(ERActionException).reason(ERExceptionReason_InvalidParamCountForConcurrentAction));
        });
    });
});

QuickSpecEnd
