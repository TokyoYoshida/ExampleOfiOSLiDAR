## Depth

Depth maps provide information on the distance between the device and the object in front of the camera.

You can get the confidence map with the following code.

```swift
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let pixcelBuffer = session.currentFrame?.sceneDepth?.depthMap
}
```

Depth map value is Float32.
