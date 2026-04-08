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
        version: "1.0.1"
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
        
        // Check for glob pattern
        if GlobExpander.isGlob(inputPath) {
            try handleGlob(inputPath)
            return
        }
        
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
        
        // Check if it's a recipe (by filename or content)
        let isRecipe = FileDetector.isRecipeFilename(inputPath) || 
                       (try? FileDetector.isRecipeContent(at: inputPath)) == true
        
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
    
    /// Handle glob pattern
    private func handleGlob(_ pattern: String) throws {
        let outputDir = output.map { PathHandler.expandTilde($0) }
        try BatchProcessor.processGlob(pattern: pattern, outputDir: outputDir, tidy: tidy)
    }
    
    /// Handle directory conversion (batch processing)
    private func handleDirectory(_ inputPath: String) throws {
        let outputDir = output.map { PathHandler.expandTilde($0) }
        
        // Check if directory is a YAML or JSON folder
        let isYAMLFolder = inputPath.contains("/YAML/") || inputPath.contains("/_YAML/")
        let isJSONFolder = inputPath.contains("/JSON/") || inputPath.contains("/_JSON/")
        
        if isYAMLFolder || isJSONFolder {
            print("Processing folder...")
            try BatchProcessor.processDirectory(inputDir: inputPath, outputDir: outputDir, tidy: tidy)
        } else {
            throw ConversionError.unsupportedFileType("Directory must contain YAML or JSON in path for batch processing")
        }
    }
    
    /// Handle --tidy flag
    private func handleTidy() throws {
        let inputPath = PathHandler.expandTilde(input)
        
        // Check for glob
        if GlobExpander.isGlob(inputPath) {
            try BatchProcessor.processGlob(pattern: inputPath, tidy: true)
            return
        }
        
        // Check if directory
        if PathHandler.directoryExists(inputPath) {
            print("WARNING! Processing all subfolders...\n")
            try BatchProcessor.processDirectory(inputDir: inputPath, tidy: true)
        } else {
            // Single file tidy
            guard FileDetector.detectFileType(inputPath) == .yaml else {
                print("Not processing \(inputPath)\n")
                return
            }
            
            try tidySingleFile(inputPath)
        }
    }
    
    /// Tidy a single YAML file
    private func tidySingleFile(_ path: String) throws {
        let yamlString = try String(contentsOfFile: path, encoding: .utf8)
        let yamlObject = try OrderedYAMLLoader.load(yaml: yamlString)
        
        guard let plValue = PropertyListValue(fromPlist: yamlObject) else {
            throw ConversionError.invalidYAMLFormat("Could not convert YAML to property list")
        }
        
        // Check if it's a recipe (by filename or content)
        let isRecipe = FileDetector.isRecipeFilename(path) || 
                       (try? FileDetector.isRecipeContent(at: path)) == true
        let yaml: String
        
        if isRecipe, var recipe = AutoPkgRecipe(from: plValue) {
            // Use RecipeYAMLGenerator for recipes to preserve ordering
            AutoPkgOptimizer.optimize(&recipe)
            yaml = try RecipeYAMLGenerator.generate(from: recipe)
            try RecipeYAMLGenerator.verify(yaml)
        } else {
            // For non-recipes, use standard Yams
            let yamlObj = convertToYamsObject(plValue)
            yaml = try Yams.dump(object: yamlObj, width: -1, sortKeys: false)
        }
        
        // Write back
        try yaml.write(toFile: path, atomically: true, encoding: .utf8)
        print("Wrote to: \(path)\n")
    }
    
    /// Helper to convert PropertyListValue to Yams object
    private func convertToYamsObject(_ value: PropertyListValue) -> Any {
        switch value {
        case .string(let str): return str
        case .integer(let int): return int
        case .double(let dbl): return dbl
        case .bool(let bool): return bool
        case .date(let date): return date
        case .data(let data): return data.base64EncodedString()
        case .array(let arr): return arr.map { convertToYamsObject($0) }
        case .dictionary(let dict): return dict.mapValues { convertToYamsObject($0) }
        }
    }
    
    /// Helper to format AutoPkg recipes
    private func formatAutoPkgRecipe(_ yaml: String) -> String {
        let lines = yaml.components(separatedBy: .newlines)
        var formatted: [String] = []
        
        let sectionsNeedingBlankLines = ["Input:", "Process:", "- Processor:", "ParentRecipeTrustInfo:"]
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var needsBlankLine = false
            
            for section in sectionsNeedingBlankLines {
                if trimmed.starts(with: section) {
                    if index > 0 && !formatted.isEmpty && !formatted.last!.trimmingCharacters(in: .whitespaces).isEmpty {
                        needsBlankLine = true
                    }
                    break
                }
            }
            
            if needsBlankLine {
                formatted.append("")
            }
            formatted.append(line)
        }
        
        var result = formatted.joined(separator: "\n")
        result = result.replacingOccurrences(of: "Process:\n\n-", with: "Process:\n-")
        
        if !result.hasSuffix("\n") {
            result += "\n"
        }
        
        return result
    }
}
