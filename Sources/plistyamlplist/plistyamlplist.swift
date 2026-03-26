import Foundation
import ArgumentParser
import Yams
import OrderedCollections

@main
struct PlistYAMLPlist: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plistyamlplist",
        abstract: "Convert between plist, YAML, and JSON formats",
        discussion: """
            If input is a PLIST file and output is omitted,
            input is converted to <input>.yaml in the same folder.
            
            If input ends in .yaml or .yml and output is omitted,
            input.yaml is converted to PLIST format with name <input>
            
            If input is a folder with 'YAML' or 'JSON' in the path,
            all yaml files in the subfolders will be converted to plists in
            the corresponding subfolder structure above the YAML or JSON folder.
            Or, if output is specified as another folder, the corresponding
            folder structure will be reproduced under the output folder.
            """,
        version: "1.0.0"
    )
    
    @Argument(help: "Input file or directory")
    var input: String
    
    @Argument(help: "Output file or directory (optional)")
    var output: String?
    
    @Flag(name: .long, help: "Tidy YAML file(s) for AutoPkg")
    var tidy: Bool = false
    
    func run() throws {
        print("plist-yaml-plist version \(Self.configuration.version)")
        
        // Handle --tidy flag
        if tidy {
            try handleTidy()
            return
        }
        
        // Expand tilde in paths
        let inputPath = PathHandler.expandTilde(input)
        
        // Check if input exists
        guard PathHandler.fileExists(inputPath) || PathHandler.directoryExists(inputPath) else {
            throw ConversionError.fileNotFound(inputPath)
        }
        
        // Determine if input is a directory
        if PathHandler.directoryExists(inputPath) {
            try handleDirectory(inputPath)
        } else {
            try handleSingleFile(inputPath)
        }
    }
    
    /// Handle single file conversion
    private func handleSingleFile(_ inputPath: String) throws {
        // Detect file type
        let fileType = FileDetector.detectFileType(inputPath)
        
        guard fileType != .unknown else {
            throw ConversionError.unsupportedFileType(inputPath)
        }
        
        // Determine output path
        let outputPath: String
        if let output = output {
            outputPath = PathHandler.expandTilde(output)
        } else {
            guard let determinedPath = PathHandler.determineOutputPath(for: inputPath, fileType: fileType) else {
                throw ConversionError.pathDoesNotExist("Could not determine output path")
            }
            outputPath = determinedPath
        }
        
        // Check if it's a recipe
        let isRecipe = FileDetector.isRecipeFilename(inputPath)
        
        // Perform conversion based on file type
        switch fileType {
        case .plist:
            print("Processing plist file...")
            try PlistToYAMLConverter.convert(inputPath: inputPath, outputPath: outputPath, isRecipe: isRecipe)
            
        case .yaml:
            print("Processing yaml file...")
            try YAMLToPlistConverter.convert(inputPath: inputPath, outputPath: outputPath)
            
        case .json:
            print("Processing json file...")
            try JSONToPlistConverter.convert(inputPath: inputPath, outputPath: outputPath)
            
        case .unknown:
            throw ConversionError.unsupportedFileType(inputPath)
        }
    }
    
    /// Handle directory conversion (batch processing)
    private func handleDirectory(_ inputPath: String) throws {
        throw ConversionError.unsupportedFileType("Directory processing not yet implemented")
    }
    
    /// Handle --tidy flag
    private func handleTidy() throws {
        throw ConversionError.unsupportedFileType("Tidy functionality not yet implemented")
    }
}
