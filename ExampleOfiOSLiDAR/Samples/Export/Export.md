## Export

You can add physical behavior by using generateCollisionShapes of ModelEntity.

You can also use PhysicsMotionComponent to give speed to an object.

```swift
let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .red, isMetallic: true)])

sphere.generateCollisionShapes(recursive: true)
sphere.physicsBody = .init()
sphere.physicsBody?.mode = .dynamic
sphere.physicsMotion =  PhysicsMotionComponent(linearVelocity: [0, 0, -0.1],
angularVelocity: [0, 0, 0])
```
