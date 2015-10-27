import Foundation
import UIKit

/**
This class takes care of transforming NSData instances into UIImage objects.

Keep in mind that at the moment this class always deserializes images through UIImagePNGRepresentation, so there may be a data usage bigger than actually required.
*/
public class ImageTransformer: TwoWayTransformer {
  public enum Error: ErrorType {
    case InvalidData
    case CannotConvertImage
  }
  
  public typealias TypeIn = NSData
  public typealias TypeOut = UIImage
  
  /// Initializes a new instance of ImageTransformer
  public init() {}
  
  /**
  Serializes an NSData instance into a UIImage
  
  - parameter val: The NSData you want to serialize
  
  - returns: A UIImage object if the input was valid, .None otherwise
  */
  public func transform(val: TypeIn) -> Result<TypeOut> {
    let result = Result<TypeOut>()
    
    GCD.background {
      if let image = UIImage(data: val) {
        GCD.main {
          result.succeed(image)
        }
      } else {
        GCD.main {
          result.fail(Error.InvalidData)
        }
      }
    }
    
    return result
  }
  
  /**
  Deserializes an UIImage instance into NSData
  
  - parameter val: The UIImage you want to deserialize
  
  - returns: An NSData instance obtained with UIImagePNGRepresentation if the input was valid, .None otherwise
  */
  public func inverseTransform(val: TypeOut) -> Result<TypeIn> {
    /* This is a waste of bytes, we should probably use a lower-level framework */
    let result = Result<TypeIn>()
    
    GCD.background {
      if let image = UIImagePNGRepresentation(val) {
        GCD.main {
          result.succeed(image)
        }
      } else {
        GCD.main {
          result.fail(Error.CannotConvertImage)
        }
      }
    }
    
    return result
  }
}