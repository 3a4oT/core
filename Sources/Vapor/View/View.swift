/**
    Loads and renders a file from the `Resources` folder
    in the Application's work directory.
*/
public class View {
    ///Currently applied RenderDrivers
    public static var renderers: [String: RenderDriver] = [:]

    var data: Data

    enum Error: ErrorProtocol {
        case InvalidPath
    }

    /**
        Attempt to load and render a file
        from the supplied path using the contextual
        information supplied.
        - context Passed to RenderDrivers
    */
    public init(workDir: String, path: String, context: [String: Any] = [:]) throws {
        let filesPath = workDir + "Resources/Views/" + path

        guard let fileBody = try? FileManager.readBytesFromFile(filesPath) else {
            self.data = Data()
            throw Error.InvalidPath
        }
        self.data = Data(fileBody)

        for (suffix, renderer) in View.renderers {
            if path.hasSuffix(suffix) {
                let template = try String(data: data)
                let rendered = try renderer.render(template: template, context: context)
                self.data = rendered.data
            }
        }

    }

}

///Allows Views to be returned in Vapor closures
extension View: ResponseRepresentable {
    public func makeResponse(for: Request) -> Response {
        return Response(status: .ok, headers: [
            "Content-Type": "text/html; charset=utf-8"
        ], body: .data(data.bytes))
    }
}
