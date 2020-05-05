//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#include "AtomicBridges.h"

@implementation AtomicBridges

+ (long)fetchAndIncrementBarrier:(_Atomic(long) *)value {
  return atomic_fetch_add(value, 1);
}

+ (long)fetchAndDecrementBarrier:(_Atomic(long) *)value {
  return atomic_fetch_sub(value, 1);
}

+ (bool)compare:(_Atomic(long) *)value withExpected:(long *)expected andSwap:(long)desired {
  return atomic_compare_exchange_strong(value, expected, desired);
}

+ (long) atomicLoad:(_Atomic(long) *)value {
  return atomic_load(value);
}

+ (bool)comparePointer:(void * volatile *)value withExpectedPointer:(void *)expected andSwapPointer:(void *)desired {
  return __sync_bool_compare_and_swap(value, expected, desired);
}

@end
