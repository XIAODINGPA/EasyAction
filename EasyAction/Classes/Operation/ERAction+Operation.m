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
 
#import "ERAction+Operation.h"
#import <EasySequence/EasySequence.h>

NSString *const ERExceptionReason_InvalidParamCountForConcurrentAction = @"param's count does NOT match the count of concurrent actions";

@implementation ERAction (Operation)

- (ERAction *)actionWithSerialAction:(ERAction *)action {
    @ezr_weakify(self)
    return [ERAction actionWithBlock:^(id  _Nullable param, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
        @ezr_strongify(self)
        EZRNode<ERActionResult *> *selfResult = [self execute:param];
        EZRNode<NSError *> *selfError = [selfResult actionError];
        EZRNode<ERActionResult *> *actionResult = [[selfResult actionResult] flattenMap:^EZRNode *_Nullable(id  _Nullable next) {
            return [action execute:next];
        }];
        EZRNode<NSError *> *actionError = [actionResult actionError];
        [error linkTo:[EZRNode merge:@[selfError, actionError]]];
        [result linkTo:[actionResult actionResult]];
    }];

}

+ (ERAction *)actionWithConcurrentActions:(NSArray<ERAction *> *)actions {
    return [ERAction actionWithBlock:^(NSArray * _Nullable params, EZRMutableNode * _Nonnull result, EZRMutableNode<NSError *> * _Nonnull error) {
        if (params == nil) {
            params = [[EZS_Sequence(actions) map:^id _Nonnull(ERAction * _Nonnull value) { return NSNull.null; }] as:NSArray.class];
        }
        if (params.count != actions.count) {
            EZR_THROW(ERActionException, ERExceptionReason_InvalidParamCountForConcurrentAction, nil);
        }
        
        EZSequence *zipSeq = [[EZSequence alloc] initWithOriginSequence:@[EZS_Sequence(actions), EZS_Sequence(params)]];
        EZSequence *actionAndParamsSeq = [EZSequence zipSequences:zipSeq];
        NSArray<EZRNode<ERActionResult *> *> *actionResults = [[actionAndParamsSeq map:^id _Nonnull(EZSequence * _Nonnull item) {
            NSArray *itemArray = [item as:NSArray.class];
            id param = itemArray[2];
            if ([param isEqual:NSNull.null]) {
                param = nil;
            }
            return [itemArray[0] execute:param];
        }] as:NSArray.class];
        NSArray<EZRNode *> *nodes = [[EZS_Sequence(actionResults) map:^id _Nonnull(EZRNode<ERActionResult *> * _Nonnull value) {
            return [value actionResult];
        }] as:NSArray.class];
        NSArray<EZRNode<NSError *> *> *errors = [[EZS_Sequence(actionResults) map:^id _Nonnull(EZRNode<ERActionResult *> * _Nonnull value) {
            return [value actionError];
        }] as:NSArray.class];
        
        [result linkTo:[EZRNode zip:nodes]];
        [error linkTo:[[EZRNode merge:errors] take:1]];
    }];
}

@end
