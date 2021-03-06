//
//  Error.swift
//  WeaverCodeGen
//
//  Created by Théophane Rupin on 3/7/18.
//

import Foundation
import WeaverDI

enum TokenError: Error, AutoEquatable {
    case invalidAnnotation(String)
    case invalidScope(String)
    case invalidCustomRefValue(String)
    case invalidConfigurationAttributeValue(value: String, expected: String)
}

enum LexerError: Error, AutoEquatable {
    case invalidAnnotation(FileLocation, underlyingError: TokenError)
}

enum ParserError: Error, AutoEquatable {
    case unexpectedToken(FileLocation)
    case unexpectedEOF(FileLocation)
    
    case unknownDependency(PrintableDependency)
    case depedencyDoubleDeclaration(PrintableDependency)
    case configurationAttributeDoubleAssignation(FileLocation, attribute: ConfigurationAttribute)
}

enum GeneratorError: Error, AutoEquatable {
    case invalidTemplatePath(path: String)
}

enum InspectorError: Error, AutoEquatable {
    case invalidAST(FileLocation, unexpectedExpr: Expr)
    case invalidGraph(PrintableDependency, underlyingError: InspectorAnalysisError)
}

enum InspectorAnalysisError: Error, AutoEquatable {
    case cyclicDependency(history: [InspectorAnalysisHistoryRecord])
    case unresolvableDependency(history: [InspectorAnalysisHistoryRecord])
    case isolatedResolverCannotHaveReferents(typeName: String?, referents: [PrintableResolver])
}

enum InspectorAnalysisHistoryRecord: AutoEquatable {
    case foundUnaccessibleDependency(PrintableDependency)
    case dependencyNotFound(PrintableDependency)
    case triedToBuildType(PrintableResolver, stepCount: Int)
    case triedToResolveDependencyInType(PrintableDependency, stepCount: Int)
}

// MARK: - Printables

protocol Printable {
    var fileLocation: FileLocation { get }
}

struct PrintableResolver: AutoEquatable, Printable {
    let fileLocation: FileLocation
    let typeName: String?
}

struct PrintableDependency: AutoEquatable, Printable {
    let fileLocation: FileLocation
    let name: String
    let typeName: String?
}

struct FileLocation: AutoEquatable, Printable {
    let line: Int?
    let file: String?
    
    var fileLocation: FileLocation {
        return self
    }
    
    static var unknown: FileLocation {
        return FileLocation(line: nil, file: nil)
    }
    
    static func file(_ file: String?) -> FileLocation {
        return FileLocation(line: nil, file: file)
    }
}

// MARK: - Description

extension TokenError: CustomStringConvertible {

    var description: String {
        switch self {
        case .invalidAnnotation(let annotation):
            return "Invalid annotation: '\(annotation)'"
        case .invalidScope(let scope):
            return "Invalid scope: '\(scope)'"
        case .invalidCustomRefValue(let value):
            return "Invalid customRef value: \(value). Expected true|false"
        case .invalidConfigurationAttributeValue(let value, let expected):
            return "Invalid configuration attribute value: \(value). Expected \(expected)"
        }
    }
}

extension LexerError: CustomStringConvertible {

    var description: String {
        switch self {
        case .invalidAnnotation(let location, let underlyingError):
            return location.xcodeLogString(.error, "\(underlyingError)")
        }
    }
}

extension ParserError: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .depedencyDoubleDeclaration(let dependency):
            return dependency.xcodeLogString(.error, "Double dependency declaration: '\(dependency.name)'")
        case .unexpectedEOF(let location):
            return location.xcodeLogString(.error, "Unexpected EOF (End of file)")
        case .unexpectedToken(let location):
            return location.xcodeLogString(.error, "Unexpected token")
        case .unknownDependency(let dependency):
            return dependency.xcodeLogString(.error, "Unknown dependency: '\(dependency.name)'")
        case .configurationAttributeDoubleAssignation(let location, let attribute):
            return location.xcodeLogString(.error, "Configuration attribute '\(attribute.name)' was already set")
        }
    }
}

extension GeneratorError: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .invalidTemplatePath(let path):
            return "Invalid template path: \(path)."
        }
    }
}

extension InspectorError: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .invalidAST(let location, let token):
            return location.xcodeLogString(.error, "Invalid AST because of token: \(token)")
        case .invalidGraph(let dependency, let underlyingIssue):
            var description = dependency.xcodeLogString(.error, "Detected invalid dependency graph starting with '\(dependency.name): \(dependency.typeName ?? "_")'. \(underlyingIssue)")
            if let notes = underlyingIssue.notes {
                description = ([description] + notes.map { $0.description }).joined(separator: "\n")
            }
            return description
        }
    }
}

extension InspectorAnalysisError: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .cyclicDependency:
            return "Detected a cyclic dependency"
        case .unresolvableDependency:
            return "Dependency cannot be resolved"
        case .isolatedResolverCannotHaveReferents:
            return "This type is flagged as isolated. It cannot have any connected referent"
        }
    }
    
    fileprivate var notes: [CustomStringConvertible]? {
        switch self {
        case .cyclicDependency(let history):
            return history
        case .isolatedResolverCannotHaveReferents(let typeName, let referents):
            return referents.map { referent in
                let message = "'\(referent.typeName ?? "_")' " +
                    "cannot depend on '\(typeName ?? "_")' because it is flagged as 'isolated'. " +
                    "You may want to set '\(typeName ?? "_").isIsolated' to 'false'"
                return referent.xcodeLogString(.error, message)
            }
        case .unresolvableDependency(let history):
            return history
        }
    }
}

extension InspectorAnalysisHistoryRecord: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .dependencyNotFound(let dependency):
            return dependency.xcodeLogString(.warning, "Could not find the dependency '\(dependency.name)' in '\(dependency.typeName ?? "_")'. You may want to register it here to solve this issue")
        case .foundUnaccessibleDependency(let dependency):
            return dependency.xcodeLogString(.warning, "Found unaccessible dependency '\(dependency.name)' in '\(dependency.typeName ?? "_")'. You may want to set its scope to '.container' or '.weak' to solve this issue")
        case .triedToBuildType(let resolver, let stepCount):
            return resolver.xcodeLogString(.warning, "Step \(stepCount): Tried to build type '\(resolver.typeName ?? "_")'")
        case .triedToResolveDependencyInType(let dependency, let stepCount):
            return dependency.xcodeLogString(.warning, "Step \(stepCount): Tried to resolve dependency '\(dependency.name)' in type '\(dependency.typeName ?? "_")'")
        }
    }
}

// MARK: - InspectorAnalysisHistoryRecord Filters

extension Array where Element == InspectorAnalysisHistoryRecord {
    
    var unresolvableDependencyDetection: [InspectorAnalysisHistoryRecord] {
        return filter {
            switch $0 {
            case .dependencyNotFound,
                 .foundUnaccessibleDependency:
                return true
            case .triedToResolveDependencyInType,
                 .triedToBuildType:
                return false
            }
        }
    }
    
    var cyclicDependencyDetection: [InspectorAnalysisHistoryRecord] {
        return buildSteps + resolutionSteps
    }
    
    var buildSteps: [InspectorAnalysisHistoryRecord] {
        return filter {
            switch $0 {
            case .triedToBuildType:
                return true
            case .dependencyNotFound,
                 .foundUnaccessibleDependency,
                 .triedToResolveDependencyInType:
                return false
            }
        }
    }
    
    var resolutionSteps: [InspectorAnalysisHistoryRecord] {
        return filter {
            switch $0 {
            case .triedToResolveDependencyInType:
                return true
            case .dependencyNotFound,
                 .foundUnaccessibleDependency,
                 .triedToBuildType:
                return false
            }
        }
    }
}

// MARK: - Utils

private enum LogLevel: String {
    case warning = "warning"
    case error = "error"
}

private extension Printable {
    
    func xcodeLogString(_ logLevel: LogLevel, _ message: String) -> String {
        switch (fileLocation.line, fileLocation.file) {
        case (.some(let line), .some(let file)):
            return "\(file):\(line + 1): \(logLevel.rawValue): \(message)."
        case (nil, .some(let file)):
            return "\(file):1: \(logLevel.rawValue): \(message)."
        case (_, nil):
            return "\(logLevel.rawValue): \(message)."
        }
    }
}

