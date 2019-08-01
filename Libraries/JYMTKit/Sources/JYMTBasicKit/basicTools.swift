//
//  basicTools.swift
//  JYMoleculeTool-Swift
//
//  Created by Jerry Yan on 6/21/19.
//  Copyright © 2019 Jerry Yan. All rights reserved.
//

import Foundation

/**
 User-friendly input
 */
public func input(name: String, type: String, defaultValue: Any? = nil, intRange:ClosedRange<Int>? = nil, doubleRange: ClosedRange<Double>? = nil, printAfterSec: Bool = false) -> String {
    let typeCode = type.lowercased()

    var pass = false
    var inputResult: String = ""
    
    while !pass {
        if defaultValue == nil {
            print("Please enter \(name): ", terminator: "")
        } else {
            print("Please enter \(name) [\(defaultValue!) by default]: ", terminator: "")
        }
        let response = readLine()
        var inputConverted: Any?
        guard let r: String = response else {
            print("Error: got nil response.")
            continue
        }
        
        if defaultValue != nil && r.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            inputResult = String(describing: defaultValue!)
            break
        }
        
        switch typeCode {
        case "string":
            inputConverted = r
        case "int":
            inputConverted = Int(r)
        case "double":
            inputConverted = Double(r)
        default:
            inputConverted = r
        }
        
        if inputConverted == nil {
            pass = false
            print("Wrong format. Please try again.")
            continue
        } else {
            if doubleRange != nil && typeCode == "double" {
                guard let inputDouble = Double(String(describing: inputConverted!)), doubleRange!.contains(inputDouble) else {
                    pass = false
                    print("Out of range. Please try again.")
                    continue
                }
            } else if intRange != nil && typeCode == "int" {
                guard let inputInt = Int(String(describing: inputConverted!)), intRange!.contains(inputInt) else {
                    pass = false
                    print("Out of range. Please try again.")
                    continue
                }
            }
            pass = true
            inputResult = String(describing: inputConverted!)
        }
    }
    
    if printAfterSec {
        print("\(name) is set as \(inputResult).")
    }
    
    return inputResult
}

/**
 Returns the string of current time.
 */
public func timeNow() -> String {
    return displayTime(Date())
}

/**
 Returns the string discribing some time locally. *(More parameters to be added later)*
 */
public func displayTime(_ time: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: time)
}

/**
 Returns a string with given total space `totSpace` filled by empty space after the given string `str`. If the length of the given string is larger than the given total space, it will directly return the string.
 
 - Parameter str: The string to be added empty space after.
 - Parameter totSpace: The total number of space (including the string itself) the string needed to be fitted in.
 
 */
public func stringWithSpace(_ str: String, _ totSpace: Int, trailing: Bool = true) -> String {
    guard totSpace >= str.count else {
        return str
    }
    if trailing {
        return str + String(repeating: "\u{0020}", count: totSpace - str.count)
    } else {
        return String(repeating: "\u{0020}", count: totSpace - str.count) + str
    }
}

/**
 The same as `stringWithSpace`, but it takes `Any` type as the input.
 */
public func toPrintWithSpace(_ item: Any, _ totSpace: Int, trailing: Bool = true) -> String {
    return stringWithSpace(String(describing: item), totSpace, trailing: trailing)
}

public extension String {
    func withSpace(_ totSpace: Int, trailing: Bool = true) -> String {
        return stringWithSpace(self, totSpace, trailing: trailing)
    }
}

/**
 To print string from the start of the console line.
 */
public func printStringInLine(_ str: String) {
    print(str, terminator: "\r")
    #if os(Linux)
    fflush(stdout)
    #else
    fflush(__stdoutp)
    #endif
}



/**
 The input for file/directory paths with a `tryAction` to determine the pass state of the inner loop.
*/
public func fileInput(name: String = "", message: String? = nil, successMessage: Bool = true, tryAction: (String) throws -> Bool) {
    var filePass = false
    var toPrint = ""
    if message != nil {
        toPrint = message!
    } else {
        toPrint = name + " path"
    }
    while !filePass {
        do {
            let filePath: String = input(name: toPrint, type: "string").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "")
            filePass = try tryAction(filePath)
            if successMessage {
                print("Successfully imported from \(name).")
            }
        } catch let error {
            print("Error:\n \(error).\n Please try again.")
        }
    }
}

/**
 Print the copyright information if the configuration is set to `release`.
 */

public func printWelcomeBanner(_ name: String) {
    #if DEBUG
    #else
    print()
    print("JYMoleculeTool - \(name)")
    print("Copyright © 2019 Jerry Yan. All rights reserved.")
    print()
    #endif
}

/**
 The program mode used by Structure Finder or related processes.
 */
public enum SFProgramMode {
    /**
     The test mode is to test whether a known molecule will pass all the filters or not. In the test mode, the program will not re-sign the coordinates.
     */
    case test
    
    /**
     The simple mode is to run with all default parameters.
     */
    case simple
    
    /**
     The ordinary mode.
     */
    case ordinary
}

/**
 A packed input module for importing `.xyz` file.
 
 - Returns: a tuple `(XYZFile, String)` where the first element is the imported XYZ file and the second element is the last component name of the `.xyz` file.
 */
public func xyzFileInput() -> (XYZFile, String) {
    var xyzSet = XYZFile()
    var fileName = ""
    fileInput(name: "XYZ file", tryAction: { (filePath) in
        xyzSet = try XYZFile(fromPath: filePath)
        fileName = URL(fileURLWithPath: filePath).lastPathComponentName
        guard xyzSet.atoms != nil && !xyzSet.atoms!.isEmpty else {
            print("No Atoms in xyz file. Can not proceed.")
            return false
        }
        return true
    })
    return (xyzSet, fileName)
}

/**
 A packed input module for importing `sabc`file.
 
 - Returns: a tuple `(SABCFile, String)` where the first element is the imported SABC file and the second element is the last component name of the `sabc` file.
 */
public func sabcFileInput() -> (SABCFile, String) {
    var sabcSet = SABCFile()
    var fileName = ""
    fileInput(name: "SABC file") { (filePath) -> Bool in
        sabcSet = try SABCFile(fromPath: filePath)
        if !sabcSet.isValid {
            print("Not a valid SABC file.")
            return false
        }
        if sabcSet.substituted!.isEmpty {
            print("No SIS information.")
            return false
        }
        fileName = URL(fileURLWithPath: filePath).lastPathComponentName
        return true
    }
    return (sabcSet, fileName)
}

/**
 A packed input module for optional selecting exporting path.
 
 - Returns: a tuple `(Bool, URL)` where the first element whether the user decided to save results or not, and the second element is the `URL` of the user-selected exporting path.
    - The second element is meaningless if the first element returns `false`.
 */
public func exportingPathInput(_ name: String = "") -> (Bool, URL) {
    var saveResults = true
    var writePath = URL(fileURLWithPath: "")
    fileInput(message: "\(name) exporting Path (leave empty if not to save)", successMessage: false) { (writePathInput) in
        if writePathInput.isEmpty {
            saveResults = false
            print("The results will not be saved.")
            return true
        } else {
            let writePathUrl = URL(fileURLWithPath: writePathInput)
            guard writePathUrl.hasDirectoryPath else {
                print("Not a valid directory. Please try again.")
                return false
            }
            writePath = writePathUrl
            print("The result will be saved in \(writePath.relativeString).")
            return true
        }
    }
    return (saveResults, writePath)
}

/**
 Create a new directory with optional sub-directories.
 
 - Returns: a tuple `(URL, [URL])` where the first element is the path of the directory (if success) and the second element is the paths of the sub-directories that has been created (if success).
 */
@discardableResult
public func createNewDirectory(_ name: String, subDirectories: [String] = [], at basePath: URL, withIntermediateDirectories: Bool = false) -> (URL, [URL]) {
    var subDirPaths = [URL]()
    do {
        let newDirectoryPath = basePath.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: newDirectoryPath, withIntermediateDirectories: withIntermediateDirectories)
        for subName in subDirectories {
            let subPath = newDirectoryPath.appendingPathComponent(subName, isDirectory: true)
            try FileManager.default.createDirectory(at: subPath, withIntermediateDirectories: withIntermediateDirectories)
            subDirPaths.append(subPath)
        }
        return (newDirectoryPath, subDirPaths)
    } catch let error {
        print("An error occured when creating a new directory: \(error).")
    }
    subDirPaths += [URL](repeating: basePath, count: subDirectories.count - subDirPaths.count)
    return (basePath, subDirPaths)
}

public extension String {
    /**
     Returns a string with self appended by the unix time.
     */
    func appendedUnixTime(_ time: Date = Date(), separator: String = "_") -> String {
        return self + separator + String(Int(time.timeIntervalSince1970))
    }
    
    /**
     Append the string with the unix time.
     */
    mutating func appendUnixTime(_ time: Date = Date(), separator: String = "_") {
        self = appendedUnixTime(time, separator: separator)
    }
}

public extension Double {
    /**
     Returns the string describing the double number with digits after decimal.
     */
    func srounded(digitsAfterDecimal: Int, option: String = "f") -> String {
        String(format: "%.\(digitsAfterDecimal)\(option)", self)
    }
}

public extension Array where Element == Double {
    /**
     Map the double array to a string array with each string describing the double element with digits after decimal.
     */
    func srounded(digitsAfterDecimal: Int, option: String = "f") -> [String] {
        self.map { String(format: "%.\(digitsAfterDecimal)\(option)", $0)}
    }
    
    /**
     Describes the `srounded(digitsAfterDecimal: Int, option: String)` as a standard array. (Mainly for printing)
     */
    func sroundedString(digitsAfterDecimal: Int, option: String = "f") -> String {
        "[" + srounded(digitsAfterDecimal: digitsAfterDecimal, option: option).joined(separator: ", ") + "]"
    }
}
