import Foundation

infix operator <?> { associativity right }

extension CacheLevel {
  
  /**
  Wraps the CacheLevel with a boolean condition on the key that controls when a get call should fail unconditionally
  
  - parameter condition: The condition closure that takes a key and returns true if the key can be fetched, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>
  
  - returns: A new BasicCache that will check for the condition before every get is dispatched to the decorated cache level
  
  The condition doesn't apply to the set, clear, onMemoryWarning calls
  */
  public func conditioned(condition: (KeyType) -> Promise<Bool>) -> BasicCache<KeyType, OutputType> {
    return BasicCache(
      getClosure: conditionedClosure(self.get, condition: condition),
      setClosure: self.set,
      clearClosure: self.clear,
      memoryClosure: self.onMemoryWarning
    )
  }
}

private func conditionedClosure<A, B>(closure: A -> Promise<B>, condition: A -> Promise<Bool>) -> (A -> Promise<B>) {
  return { input in
    let request = Promise<B>()
    
    condition(input)
      .onSuccess { passesCondition in
        if passesCondition {
          request.mimic(closure(input))
        } else {
          request.fail(FetchError.ConditionNotSatisfied)
        }
      }
      .onFailure(request.fail)
    
    return request
  }
}

extension OneWayTransformer {
  /**
  Wraps the transformer with a boolean condition on the input that controls when a transformation should fail unconditionally.
   
  - parameter condition: The condition closure that takes an input and returns true if the input can be transformed, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>
   
  - returns: A new OneWayTransformer that will check for the condition before every transformation is dispatched to the decorated transformer
  */
  public func conditioned(condition: (TypeIn) -> Promise<Bool>) -> OneWayTransformationBox<TypeIn, TypeOut> {
    return OneWayTransformationBox(transform: conditionedClosure(self.transform, condition: condition))
  }
}

extension TwoWayTransformer {
  /**
  Wraps the transformer with a boolean condition on the input and a boolean condition on the "inverse input" that controls when a transformation on either side should fail unconditionally.
   
  - parameter condition: The condition closure used for normal transformations that takes an input and returns true if the input can be transformed, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>
  - parameter inverseCondition: The condition closure used for inverse transformations that takes a TypeOut argument and returns true if the input can be transformed, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>.
   
  - returns: A new TwoWayTransformer that will check for the conditions before every transformation is dispatched to the decorated transformer
  */
  public func conditioned(condition: (TypeIn) -> Promise<Bool>, inverseCondition: (TypeOut) -> Promise<Bool>) -> TwoWayTransformationBox<TypeIn, TypeOut> {
    return TwoWayTransformationBox(
      transform: conditionedClosure(self.transform, condition: condition),
      inverseTransform: conditionedClosure(self.inverseTransform, condition: inverseCondition)
    )
  }
}

/**
Wraps a CacheLevel with a boolean condition on the key that controls when a get call should fail unconditionally

- parameter condition: The condition closure that takes a key and returns true if the key can be fetched, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>
- parameter cache: The cache level you want to decorate

- returns: A new BasicCache that will check for the condition before every get is dispatched to the decorated cache level

The condition doesn't apply to the set, clear, onMemoryWarning calls
*/
public func <?><A: CacheLevel>(condition: (A.KeyType) -> Promise<Bool>, cache: A) -> BasicCache<A.KeyType, A.OutputType> {
  return cache.conditioned(condition)
}

/**
Wraps a CacheLevel with a boolean condition on the key that controls when a get call should fail unconditionally

- parameter condition: The condition closure that takes a key and returns true if the key can be fetched, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>
- parameter fetchClosure: The fetch closure to decorate

- returns: A new BasicCache that will check for the condition before every get is dispatched to the decorated cache level
*/
public func <?><A, B>(condition: A -> Promise<Bool>, fetchClosure: (key: A) -> Promise<B>) -> BasicCache<A, B> {
  return wrapClosureIntoFetcher(fetchClosure).conditioned(condition)
}

/**
Wraps a CacheLevel with a boolean condition on the key that controls when a get call should fail unconditionally

- parameter fetchClosure: The fetch closure to decorate
- parameter condition: The condition closure that takes a key and returns true if the key can be fetched, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>

- returns: A new BasicCache that will check for the condition before every get is dispatched to the decorated cache level
*/
@available(*, deprecated=0.5)
public func conditioned<A, B>(fetchClosure: (key: A) -> Promise<B>, condition: A -> Promise<Bool>) -> BasicCache<A, B> {
  return wrapClosureIntoFetcher(fetchClosure).conditioned(condition)
}

/**
Wraps a CacheLevel with a boolean condition on the key that controls when a get call should fail unconditionally

- parameter cache: The cache level you want to decorate
- parameter condition: The condition closure that takes a key and returns true if the key can be fetched, or false if the request should fail unconditionally. The closure can also pass a specific error in case it wants to explicitly communicate why it failed. The condition can be asynchronous and has to return a Promise<Bool>

- returns: A new BasicCache that will check for the condition before every get is dispatched to the decorated cache level

The condition doesn't apply to the set, clear, onMemoryWarning calls
*/
@available(*, deprecated=0.5)
public func conditioned<A: CacheLevel>(cache: A, condition: (A.KeyType) -> Promise<Bool>) -> BasicCache<A.KeyType, A.OutputType> {
  return cache.conditioned(condition)
}
