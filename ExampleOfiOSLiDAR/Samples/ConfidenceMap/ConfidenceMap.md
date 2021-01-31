## Confidence Map

Confidence maps provide accuracy of depth data.
It can be obtained in the same size as the depth map.

You can get the confidence map with the following code.

```swift
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let pixcelBuffer = session.currentFrame?.sceneDepth?.confidenceMap
}
```

Depth map value is Float32, but the confidence map value is UInt8.
