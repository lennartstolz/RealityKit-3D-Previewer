import SwiftUI
import RealityKit
import Combine

struct ContentView: View {
    var body: some View {
        VStack {
            HStack {
                Image("close-button")
                    .padding(.leading, 20)
                Spacer(minLength: 1)
            }
            .frame(height: 40)
            ZStack {
                ARView(model: "DEQ19WES92620-131615")
                VStack {
                    HStack {
                            HStack {
                                Spacer(minLength: 1)
                                ZStack {
                                    Color.white
                                        .frame(width: 70, height: 70)
                                        .cornerRadius(40)
                                        .padding(.trailing, 20)
                                    Image("360-badge")
                                        .frame(width: 70, height: 70)
                                        .padding(.trailing, 20)
                                }
                            }
                        .padding(.top, 30)
                        .frame(height: 120, alignment: .top)
                    }
                    Spacer(minLength: 1)
                }
            }
                .padding(.bottom, 10)
            HStack {
                Image("ar-badge")
                    .padding(.leading, 20)
                    .padding(.trailing, 8)
                Text("View in AR")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.darkGray))
                Spacer(minLength: 1)

            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

var subscriptions = Set<Combine.AnyCancellable>()

struct ARView: UIViewRepresentable {

    private let model: String


    init(model: String) {
        self.model = model
    }

    // MARK: - UIViewRepresentable

    typealias UIViewType = RealityKit.ARView

    func makeUIView(context: Context) -> RealityKit.ARView {
        let view = RealityKit.ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: true)

        ModelEntity
            .loadModelAsync(named: model)
            .sink(receiveCompletion: {_ in }) { model in
                model.generateCollisionShapes(recursive: true)
                // Unfortunately, one of the models I added for testing this protoype has some scaling issue(s).
                model.scale = self.model == "DEQ19WES92620-131615" ? [0.01, 0.01, 0.01] : [1, 1, 1]

                // The models anchoring
                let anchor = AnchorEntity(world: [0, -0.25, 0])
                anchor.addChild(model)
                view.installGestures([.rotation, .scale], for: model)
                view.scene.addAnchor(anchor)

                // The shadow catching plane is done as a simple "plane" mesh.
                let mesh = MeshResource.generatePlane(width: 5, depth: 5)
                let material = OcclusionMaterial(receivesDynamicLighting: true)
                let catcher = ModelEntity(mesh: mesh, materials: [material])
                let catcherAnchor = AnchorEntity(world: [0, -0.25, 0])
                catcherAnchor.addChild(catcher)
                view.scene.addAnchor(catcherAnchor)
            }
            .store(in: &subscriptions)

        // Set a light gray background to the ARView - sorry for our weird design ;)
        let subtileGray = UIColor.black.withAlphaComponent(0.02)
        view.environment.background = .color(subtileGray)

        // Custom directional light setup.
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2_000
        directionalLight.light.isRealWorldProxy = true
        directionalLight.light.color = .white

        directionalLight.shadow = DirectionalLightComponent.Shadow()

        directionalLight.orientation = simd_quatf(angle: -.pi/2,
                                                   axis: [1,0,0])

        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(directionalLight)
        view.scene.addAnchor(lightAnchor)

        // Custom camera setup
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: [0, 0.25, 2])
        cameraAnchor.addChild(camera)
        view.scene.addAnchor(cameraAnchor)

        return view
    }

    func updateUIView(_ uiView: RealityKit.ARView, context: Context) {

    }



}
