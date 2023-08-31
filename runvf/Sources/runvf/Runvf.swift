import ArgumentParser
import Foundation
import Virtualization

class VirtualMachineDelegate: NSObject, VZVirtualMachineDelegate {
  var virtualMachine: VZVirtualMachine?
  let originalAttributes: termios

  init(_ virtualMachine: VZVirtualMachine, originalAttributes: termios) {
    self.virtualMachine = virtualMachine
    self.originalAttributes = originalAttributes
    super.init()
    virtualMachine.delegate = self
  }

  func run() throws {
    DispatchQueue.main.async {
      self.virtualMachine?.start { result in
        switch result {
        case .success:
          print("Started")
        case .failure(let error):
          self.restoreTTY()
          print("Failed to start: \(error)")
        }
      }
    }
  }
  func restoreTTY() {
    var attributes = originalAttributes
    tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &attributes)
  }

  func guestDidStop(_ virtualMachine: VZVirtualMachine) {
    restoreTTY()
    print("Guest stopped")
  }
  func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
    restoreTTY()
    print("Guest stopped with error: \(error)")
  }

  @available(macOS, introduced: 12.0)
  func virtualMachine(
    _ virtualMachine: VZVirtualMachine, networkDevice: VZNetworkDevice,
    attachmentWasDisconnectedWithError error: Error
  ) {
    print("Network device \(networkDevice) was disconnected with error: \(error)")
  }
}

struct Bootspec: Codable {
  let bootspec: Spec

  struct Spec: Codable {
    let `init`: String
    let kernel: String
    let initrd: String
    let initrdSecrets: String
    let kernelParams: [String]
    let label: String
    let system: String
    let toplevel: String
  }
  private enum CodingKeys: String, CodingKey {
    case bootspec = "org.nixos.bootspec.v1"
  }
}

@main
struct Runvf: ParsableCommand {

  struct Options: ParsableArguments {
    @Option var memorySize: UInt64 = 512 * 1024 * 1024
    @Option var cpuCount: Int = 1

    func toVirtualMachineConfiguration() -> VZVirtualMachineConfiguration {
      let config = VZVirtualMachineConfiguration()
      config.cpuCount = cpuCount
      config.memorySize = memorySize
      return config
    }
  }

  struct BootEFI: ParsableCommand {
    @OptionGroup var options: Options

    @Option var variableStore: String?
    @Argument var image: String?

    func validate() throws {
      guard #available(macOS 12, *) else {
        throw ValidationError("EFI boot is only supported on macOS 12 and later")
      }
    }
  }

  struct Boot: ParsableCommand {
    @OptionGroup var options: Options

    @Option var bootspec: String?

    @Option var nixStoreImage: String?

    func createConfig() throws -> VZVirtualMachineConfiguration {

      let config = options.toVirtualMachineConfiguration()
      if let bootspec = bootspec {
        let bootspec: Bootspec = try JSONDecoder().decode(
          Bootspec.self, from: Data(contentsOf: URL(fileURLWithPath: bootspec)))
        let bootLoader = VZLinuxBootLoader(
          kernelURL: URL(fileURLWithPath: bootspec.bootspec.kernel))
        bootLoader.initialRamdiskURL = URL(fileURLWithPath: bootspec.bootspec.initrd)
        var kernelParams = bootspec.bootspec.kernelParams
        kernelParams.append("init=\(bootspec.bootspec.`init`)")
        bootLoader.commandLine = bootspec.bootspec.kernelParams.joined(separator: " ")
        config.bootLoader = bootLoader
      } else {
        throw ValidationError("No bootspec specified")
      }

      config.serialPorts = [createConsoleConfiguration()]
      try config.validate()
      return config
    }
    func createConsoleConfiguration() -> VZSerialPortConfiguration {
      let consoleConfiguration = VZVirtioConsoleDeviceSerialPortConfiguration()
      let stdioAttachment = VZFileHandleSerialPortAttachment(
        fileHandleForReading: FileHandle.standardInput,
        fileHandleForWriting: FileHandle.standardOutput)
      consoleConfiguration.attachment = stdioAttachment
      return consoleConfiguration
    }

    func setupTTY() -> termios {
      var attributes = termios()
      tcgetattr(FileHandle.standardInput.fileDescriptor, &attributes)
      let originalAttributes = attributes

      // istty
      if isatty(FileHandle.standardInput.fileDescriptor) != 0 {
        cfmakeraw(&attributes)
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &attributes)
      }
      return originalAttributes
    }

    mutating func run() throws {
      let config = try createConfig()
      let delegate = VirtualMachineDelegate(
        VZVirtualMachine(configuration: config), originalAttributes: setupTTY())
      try delegate.run()
      RunLoop.main.run()
    }
  }

  static var configuration = CommandConfiguration(
    abstract: "Run virtual machines on macOS",

    subcommands: [Boot.self, BootEFI.self],
    defaultSubcommand: Boot.self)

}
