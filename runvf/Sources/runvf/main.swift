/*
Abstract:
A command-line utility that runs Linux in a virtual machine.
*/

import Foundation
import Virtualization

// MARK: Parse the Command Line

guard CommandLine.argc == 2 else {
    printUsageAndExit()
}

let inputFileHandle = FileHandle.standardInput
let outputFileHandle = FileHandle.standardOutput

// Put stdin into raw mode, disabling local echo, input canonicalization,
// and CR-NL mapping.
var attributes = termios()
tcgetattr(inputFileHandle.fileDescriptor, &attributes)

let imageURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: false)


func createBlockDeviceConfiguration() -> VZVirtioBlockDeviceConfiguration{
    guard let attachment = try? VZDiskImageStorageDeviceAttachment(url: imageURL, readOnly: true) else {
        fatalError("Failed to create main disk attachment")
    }
    return VZVirtioBlockDeviceConfiguration(attachment: attachment)
}

func createNetworkDeviceConfiguration() -> VZNetworkDeviceConfiguration {
    let config =  VZVirtioNetworkDeviceConfiguration()
    config.attachment = VZNATNetworkDeviceAttachment()
    return config
}

// MARK: Create the Virtual Machine Configuration

let configuration = VZVirtualMachineConfiguration()
configuration.cpuCount = 6
configuration.memorySize = VZVirtualMachineConfiguration.maximumAllowedMemorySize
configuration.serialPorts = [ createConsoleConfiguration() ]

configuration.entropyDevices = [ VZVirtioEntropyDeviceConfiguration() ]

let platform = VZGenericPlatformConfiguration()
platform.machineIdentifier = VZGenericMachineIdentifier()

configuration.platform = platform

let bootloader = VZEFIBootLoader()
bootloader.variableStore = createOrGetVariableStore()
configuration.bootLoader = bootloader
configuration.storageDevices = [createBlockDeviceConfiguration()]
configuration.networkDevices = [createNetworkDeviceConfiguration()]

do {
    try configuration.validate()
} catch {
    print("Failed to validate the virtual machine configuration. \(error)")
    exit(EXIT_FAILURE)
}

// MARK: Instantiate and Start the Virtual Machine

let virtualMachine = VZVirtualMachine(configuration: configuration)

let delegate = Delegate()
virtualMachine.delegate = delegate

virtualMachine.start { (result) in
    if case let .failure(error) = result {
        print("Failed to start the virtual machine. \(error)")
        exit(EXIT_FAILURE)
    }
}

RunLoop.main.run(until: Date.distantFuture)

// MARK: - Virtual Machine Delegate

class Delegate: NSObject {
}

extension Delegate: VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        tcsetattr(inputFileHandle.fileDescriptor, TCSANOW, &attributes)
        print("The guest shut down. Exiting.")
        exit(EXIT_SUCCESS)
    }
}

// MARK: - Helper Functions


func createOrGetVariableStore() -> VZEFIVariableStore {
    let efivariableStoreURL = URL(fileURLWithPath: "efistore", relativeTo:  FileManager.default.homeDirectoryForCurrentUser)
    if let efivariableStore = try? VZEFIVariableStore(creatingVariableStoreAt: efivariableStoreURL) {
        return efivariableStore
    } else {
        let efivariableStore = VZEFIVariableStore(url: efivariableStoreURL)
        return efivariableStore
    }
}

/// Creates a serial configuration object for a virtio console device,
/// and attaches it to stdin and stdout.
func createConsoleConfiguration() -> VZSerialPortConfiguration {
    let consoleConfiguration = VZVirtioConsoleDeviceSerialPortConfiguration()
    var attributes2 = attributes
    cfmakeraw(&attributes2)
    tcsetattr(inputFileHandle.fileDescriptor, TCSANOW, &attributes2)

    let stdioAttachment = VZFileHandleSerialPortAttachment(fileHandleForReading: inputFileHandle,
                                                           fileHandleForWriting: outputFileHandle)

    consoleConfiguration.attachment = stdioAttachment

    return consoleConfiguration
}

func printUsageAndExit() -> Never {
    print("Usage: \(CommandLine.arguments[0]) <image-url>")
    exit(EX_USAGE)
}
