## Export

You can convert it to MDLMesh using the ARMeshAnchor geometory property. 

MDLMesh can then be exported to an .obj file.

```swift
// get all mesh anchors
let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }
```

tanks to Stack Overflow answer: https://stackoverflow.com/questions/61063571/arkit-3-5-how-to-export-obj-from-new-ipad-pro-with-lidar
