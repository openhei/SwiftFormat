//
//  OptionsDescriptorTest.swift
//  SwiftFormatTests
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//

@testable import SwiftFormat
import XCTest

class OptionsDescriptorTest: XCTestCase {
    typealias OptionArgumentMapping<OPT> = (optionValue: OPT, argumentValue: String)

    func validateSut(_ sut: FormatOptions.Descriptor,
                     id: String,
                     name: String,
                     argumentName: String,
                     propertyName: String,
                     testName: String = #function) {
        XCTAssertEqual(sut.id, id, "\(testName) : id is -> \(id)")
        XCTAssertEqual(sut.name, name, "\(testName) : id is -> \(name)")
        XCTAssertEqual(sut.argumentName, argumentName, "\(testName) : id is -> \(argumentName)")
        XCTAssertEqual(sut.propertyName, propertyName, "\(testName) : id is -> \(propertyName)")
    }

    func validateSutThrowFormatErrorOptions(_ sut: FormatOptions.Descriptor, invalidArguments: String = "invalid", testName: String = #function) {
        var options = FormatOptions()
        XCTAssertThrowsError(try sut.toOptions(invalidArguments, &options),
                             "\(testName): Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false, "\(testName): Throws a FormatError.options error")
                return
            }
        }
    }
}

// MARK: - They all exists

extension OptionsDescriptorTest {
    func allOptionsPropertyName() -> [String] {
        return Mirror(reflecting: FormatOptions()).children.flatMap { $0.label }
    }

//    let allArguments = Set(formatArguments + fileArguments)
//    let allOptions = allOptionsPropertyName()
//    XCTAssertTrue(allOptions.contains(sut.propertyName), "Property Name exist on FormatOptions")
//    XCTAssertTrue(allArguments.contains(sut.argumentName), "Argument Name exist in declared format and file arguments")
}

// MARK: - Binary Options

extension OptionsDescriptorTest {
    func validateArgumentsBinaryType(sut: FormatOptions.Descriptor, controlTrue: [String], controlFalse: [String], default: Bool, testName: String = #function) {
        let values: (true: [String], false: [String]) = sut.type.associatedValue()

        let defaultControl = `default` ? controlTrue : controlFalse
        XCTAssertTrue(defaultControl.contains(sut.defaultArgument), "\(testName): Default argument map to \(`default`)")

        XCTAssertEqual(values.true[0], controlTrue[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(values.false[0], controlFalse[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(Set(values.true), Set(controlTrue), "\(testName): All possible true value have representation")
        XCTAssertEqual(Set(values.false), Set(controlFalse), "\(testName): All possible false value have representation")
    }

    func validateFromOptionsBinaryType(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, Bool>, mapping: [String: Bool], functionName: String = #function) {
        var options = FormatOptions()
        for (argument, propertyValue) in mapping {
            options[keyPath: keyPath] = propertyValue
            XCTAssertEqual(sut.fromOptions(options), argument, "\(functionName): propertye value \(propertyValue) map to \(argument)")
        }
    }

    func validateFromArgumentsBinaryType(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, Bool>, functionName: String = #function) {
        var options = FormatOptions()

        let values: (true: [String], false: [String]) = sut.type.associatedValue()
        let mappings: [(String, Bool)] = values.true.map { ($0, true) } + values.false.map { ($0, false) }

        mappings.forEach {
            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): argument: \($0.0) transform to options Value: \($0.1)")

            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): uppercased argument: \($0.0) transform to options Value: \($0.1)")

            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): capitalized argument: \($0.0) transform to options Value: \($0.1)")
        }
    }
}

// MARK: -

extension OptionsDescriptorTest {
    func test_voidRepresentation() {
        let sut = FormatOptions.Descriptor.useVoid
        validateSut(sut, id: "void-representation", name: "empty", argumentName: "empty", propertyName: "useVoid")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["void"], controlFalse: ["tuple", "tuples"], default: true)
        validateFromOptionsBinaryType(sut: sut, keyPath: \FormatOptions.useVoid, mapping: ["tuples": false, "void": true])
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.useVoid)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_allowInlineSemicolons() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        validateSut(sut, id: "allow-inline-semicolons", name: "allowInlineSemicolons", argumentName: "semicolons", propertyName: "allowInlineSemicolons")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["inline"], controlFalse: ["never", "false"], default: true)
        validateFromOptionsBinaryType(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons, mapping: ["never": false, "inline": true])
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - List Options

extension OptionsDescriptorTest {
    func validateArgumentsListType(sut: FormatOptions.Descriptor, validArguments: Set<String>, default: String, functionName: String = #function) {
        let values: [String] = sut.type.associatedValue()

        XCTAssertEqual(Set(values), validArguments, "\(functionName): All valid arguments are accounted for")
        XCTAssertEqual(sut.defaultArgument, `default`, "\(functionName): Default argument is \(`default`)")
        XCTAssertTrue(validArguments.contains(sut.defaultArgument), "\(functionName): Default argument is part of the valide arguments")
    }

    func validateFromOptionsListType<T>(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, T>, expectedMapping: [OptionArgumentMapping<T>], invalid: T?, testName: String = #function) {
        var options = FormatOptions()
        for item in expectedMapping {
            options[keyPath: keyPath] = item.optionValue
            XCTAssertEqual(sut.fromOptions(options), item.argumentValue, "\(testName): Option is transform to argument")
        }

        if let invalid = invalid {
            options[keyPath: keyPath] = invalid
            XCTAssertEqual(sut.fromOptions(options), sut.defaultArgument, "invalid input return the defautl value")
        }
    }

    func validateFromArgumentsListType<T: Equatable>(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, T>, expectedMapping: [OptionArgumentMapping<T>], testName: String = #function) {
        var options = FormatOptions()

        for item in expectedMapping {
            try! sut.toOptions(item.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], item.optionValue, "\(testName): argument: \(item.argumentValue) transform to options Value: \(item.optionValue)")
            try! sut.toOptions(item.argumentValue.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], item.optionValue, "\(testName): uppercased argument: \(item.argumentValue) transform to options Value: \(item.optionValue)")
            try! sut.toOptions(item.argumentValue.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], item.optionValue, "\(testName): capitalized argument: \(item.argumentValue) transform to options Value: \(item.optionValue)")
        }
    }
}

// MARK: -

extension OptionsDescriptorTest {
    func test_ifdefIndent() {
        let sut = FormatOptions.Descriptor.ifdefIndent
        let expectedMapping: [OptionArgumentMapping<IndentMode>] = [
            (optionValue: IndentMode.indent, argumentValue: "indent"),
            (optionValue: IndentMode.noIndent, argumentValue: "noindent"),
            (optionValue: IndentMode.outdent, argumentValue: "outdent"),
        ]

        validateSut(sut, id: "if-def-indent-mode", name: "ifdefIndent", argumentName: "ifdef", propertyName: "ifdefIndent")
        validateArgumentsListType(sut: sut, validArguments: ["indent", "noindent", "outdent"], default: "indent")
        validateFromOptionsListType(sut: sut, keyPath: \FormatOptions.ifdefIndent, expectedMapping: expectedMapping, invalid: nil)
        validateFromArgumentsListType(sut: sut, keyPath: \FormatOptions.ifdefIndent, expectedMapping: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_linebreakChar() {
        let sut = FormatOptions.Descriptor.lineBreak
        let expectedMapping: [OptionArgumentMapping<String>] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]
        validateSut(sut, id: "linebreak-character", name: "linebreak", argumentName: "linebreaks", propertyName: "linebreak")
        validateArgumentsListType(sut: sut, validArguments: ["cr", "lf", "crlf"], default: "lf")
        validateFromOptionsListType(sut: sut, keyPath: \FormatOptions.linebreak, expectedMapping: expectedMapping, invalid: "invalid")
        validateFromArgumentsListType(sut: sut, keyPath: \FormatOptions.linebreak, expectedMapping: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - Free Text Options

extension OptionsDescriptorTest {
    typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    func validateArgumentsFreeTextType(sut: FormatOptions.Descriptor, expectations: [FreeTextValidationExpectation], default: String, testName: String = #function) {
        guard case let FormatOptions.Descriptor.ArgumentType.freeText(validator) = sut.type else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(sut.defaultArgument, `default`)
        expectations.forEach {
            XCTAssert(validator($0.input) == $0.isValid, "\(testName): \($0.input) isValid: \($0.isValid)")
        }
    }

    func validateFromOptionsFreeTextType<T>(sut: FormatOptions.Descriptor,
                                            keyPath: WritableKeyPath<FormatOptions, T>,
                                            expectations: [OptionArgumentMapping<T>],
                                            testName: String = #function) {
        var options = FormatOptions()
        expectations.forEach {
            options[keyPath: keyPath] = $0.optionValue
            XCTAssertEqual(sut.fromOptions(options), $0.argumentValue, "\(testName): option: \($0.optionValue) map to argumentValue: \($0.argumentValue)")
        }
    }

    func validateFromArgumentsFreeTextType<T: Equatable>(sut: FormatOptions.Descriptor,
                                                         keyPath: WritableKeyPath<FormatOptions, T>,
                                                         expectations: [OptionArgumentMapping<T>],
                                                         testName: String = #function) {
        var options = FormatOptions()
        expectations.forEach {
            try! sut.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \($0.optionValue)")
            try! sut.toOptions($0.argumentValue.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \($0.optionValue)")
            try! sut.toOptions($0.argumentValue.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \($0.optionValue)")
        }
    }
}

// MARK: - 

extension OptionsDescriptorTest {
    func test_decimalGrouping() {
        let sut = FormatOptions.Descriptor.decimalGrouping
        let expectations: [FreeTextValidationExpectation] = [
            (input: "3,4", isValid: true),
            (input: " 3 , 5 ", isValid: true),
            (input: "ignore", isValid: true),
            (input: "none", isValid: true),
            (input: "4", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<Grouping>] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<Grouping>] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]

        validateSut(sut, id: "decimal-grouping", name: "decimalGrouping", argumentName: "decimalgrouping", propertyName: "decimalGrouping")
        validateArgumentsFreeTextType(sut: sut, expectations: expectations, default: "3,6")
        validateFromOptionsFreeTextType(sut: sut, keyPath: \FormatOptions.decimalGrouping, expectations: fromOptionExpectations)
        validateFromArgumentsFreeTextType(sut: sut, keyPath: \FormatOptions.decimalGrouping, expectations: fromArgumentExpectations)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_indentation() {
        let sut = FormatOptions.Descriptor.indentation
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "tabbed", isValid: true),
            (input: "tabs", isValid: true),
            (input: "tAb", isValid: true),
            (input: "TabbeD", isValid: true),
            (input: "TABS", isValid: true),
            (input: "2", isValid: true),
            (input: "4", isValid: true),
            (input: " 4", isValid: true),
            (input: "4 ", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "1234", argumentValue: "4"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: "\t", argumentValue: "tab"),
            (optionValue: "\t", argumentValue: "tabbed"),
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "    ", argumentValue: "4"),
        ]

        validateSut(sut, id: "indentation", name: "indent", argumentName: "indent", propertyName: "indent")
        validateArgumentsFreeTextType(sut: sut, expectations: validations, default: "4")
        validateFromOptionsFreeTextType(sut: sut, keyPath: \FormatOptions.indent, expectations: fromOptionExpectations)
        validateFromArgumentsFreeTextType(sut: sut, keyPath: \FormatOptions.indent, expectations: fromArgumentExpectations)
        validateSutThrowFormatErrorOptions(sut)
    }
}
