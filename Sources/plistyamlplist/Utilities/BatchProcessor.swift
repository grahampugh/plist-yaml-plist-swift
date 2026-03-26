import Foundation
import Yams

/// Handles glob pattern expansion and batch file operations
struct GlobExpander {
    
    /// Expand a glob pattern to matching file paths
    /// - Parameter pattern: Glob pattern (e.g., "/path/to/*.yaml")
    /// - Returns: Array of matching file paths
    static func expand(_ pattern: String) -> [String] {
        var gt = glob_t()
        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        
        // Expand the glob pattern
        if glob(pattern, flags, nil, &gt) == 0 {
            let matches = (0..<Int(gt.gl_matchc)).compactMap { index -> String? in
                guard let cString = gt.gl_pathv[index] else { return nil }
                return String(cString: cString)
            }
            globfree(&gt)
            return matches
        }
        
        globfree(&gt)
        return []
    }
    
    /// Check if a string contains glob characters
    static func isGlob(_ string: String) -> Bool {
        return string.contains("*") || string.contains("?") || string.contains("[")
    }
    
    /// Extract the directory and glob pattern from a path
    /// - Parameter path: Path potentially containing glob
    /// - Returns: Tuple of (directory, pattern) or nil if no glob
    static func extractGlob(from path: String) -> (directory: String, pattern: String)? {
        guard isGlob(path) else { return nil }
        
        let url = URL(fileURLWithPath: path)
        let filename = url.lastPathComponent
        let directory = url.deletingLastPathComponent().path
        
        return (directory, filename)
    }
}

/// Handles batch file processing operations
struct BatchProcessor {
    
    /// Process all files matching a glob pattern
    static func processGlob(pattern: String, outputDir: String? = nil, tidy: Bool = false) throws {
        let files = GlobExpander.expand(pattern)
        
        guard !files.isEmpty else {
            print("No files matched pattern: \(pattern)")
            return
        }
        
        print("Processing \(files.count) file(s)...")
        
        for file in files {
            // Skip directories
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file, isDirectory: &isDir), !isDir.boolValue else {
                continue
            }
            
            let fileType = FileDetector.detectFileType(file)
            
            // Determine output path
            let outputPath: String
            if let outputDir = outputDir {
                let filename = URL(fileURLWithPath: file).lastPathComponent
                let baseName = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
                outputPath = (outputDir as NSString).appendingPathComponent(baseName)
            } else {
                guard let determined = PathHandler.determineOutputPath(for: file, fileType: fileType) else {
                    print("ERROR: Could not determine output path for \(file)")
                    continue
                }
                outputPath = determined
            }
            
            // Convert the file
            do {
                try convertSingleFile(input: file, output: outputPath, fileType: fileType, tidy: tidy)
            } catch {
                print("ERROR: Failed to convert \(file): \(error.localizedDescription)")
            }
        }
    }
    
    /// Process all files in a directory recursively
    static func processDirectory(inputDir: String, outputDir: String? = nil, tidy: Bool = false) throws {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: inputDir) else {
            throw ConversionError.cannotReadFile(inputDir)
        }
        
        var processedCount = 0
        
        for case let file as String in enumerator {
            let fullPath = (inputDir as NSString).appendingPathComponent(file)
            
            // Skip directories
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue else {
                continue
            }
            
            let fileType = FileDetector.detectFileType(fullPath)
            
            // For YAML/JSON folders, process conversion files
            if fileType == .yaml || fileType == .json {
                let outputPath: String
                if let outputDir = outputDir {
                    // Replicate directory structure in output
                    let relativePath = file
                    let baseName = URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent
                    let subDir = URL(fileURLWithPath: relativePath).deletingLastPathComponent().path
                    let outputSubDir = (outputDir as NSString).appendingPathComponent(subDir)
                    
                    // Create output directory if needed
                    try? fileManager.createDirectory(atPath: outputSubDir, withIntermediateDirectories: true)
                    
                    outputPath = (outputSubDir as NSString).appendingPathComponent(baseName)
                } else {
                    guard let determined = PathHandler.determineOutputPath(for: fullPath, fileType: fileType) else {
                        continue
                    }
                    outputPath = determined
                }
                
                do {
                    try convertSingleFile(input: fullPath, output: outputPath, fileType: fileType, tidy: tidy)
                    processedCount += 1
                } catch {
                    print("ERROR: Failed to convert \(fullPath): \(error.localizedDescription)")
                }
            }
        }
        
        print("Processed \(processedCount) file(s)")
    }
    
    /// Convert a single file based on its type
    private static func convertSingleFile(input: String, output: String, fileType: FileType, tidy: Bool) throws {
        let isRecipe = FileDetector.isRecipeFilename(input)
        
        switch fileType {
        case .plist:
            try PlistToYAMLConverter.convert(inputPath: input, outputPath: output, isRecipe: isRecipe)
            
        case .yaml:
            if tidy {
                try tidyYAMLFile(input)
            } else {
                try YAMLToPlistConverter.convert(inputPath: input, outputPath: output)
            }
            
        case .json:
            try JSONToPlistConverter.convert(inputPath: input, outputPath: output)
            
        case .unknown:
            throw ConversionError.unsupportedFileType(input)
        }
    }
    
    /// Tidy a YAML file in place (reformat for AutoPkg)
    private static func tidyYAMLFile(_ path: String) throws {
        // Read YAML with order preservation
        let yamlString = try String(contentsOfFile: path, encoding: .utf8)
        let yamlObject = try OrderedYAMLLoader.load(yaml: yamlString)
        
        guard let plValue = PropertyListValue(fromPlist: yamlObject) else {
            throw ConversionError.invalidYAMLFormat("Could not parse YAML")
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
            let yamlObj = convertToYamsObjectHelper(plValue)
            yaml = try Yams.dump(object: yamlObj, width: -1, sortKeys: false)
        }
        
        // Write back
        try yaml.write(toFile: path, atomically: true, encoding: .utf8)
        print("Wrote to: \(path)\n")
    }
    
    /// Convert PropertyListValue to Yams object
    private static func convertToYamsObjectHelper(_ value: PropertyListValue) -> Any {
        switch value {
        case .string(let str): return str
        case .integer(let int): return int
        case .double(let dbl): return dbl
        case .bool(let bool): return bool
        case .date(let date): return date
        case .data(let data): return data.base64EncodedString()
        case .array(let arr): return arr.map { convertToYamsObjectHelper($0) }
        case .dictionary(let dict): return dict.mapValues { convertToYamsObjectHelper($0) }
        }
    }
    
    /// Format AutoPkg recipes
    private static func formatAutoPkgRecipeHelper(_ yaml: String) -> String {
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

