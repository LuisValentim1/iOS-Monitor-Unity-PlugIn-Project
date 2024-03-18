import Foundation
import Metal
import QuartzCore
import MachO

public class SystemMonitor {
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
    }
    
    typealias host_cpu_load_info_t = host_cpu_load_info_data_t

    let HOST_CPU_LOAD_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    func host_cpu_load_info() -> host_cpu_load_info_t {
        var count = HOST_CPU_LOAD_INFO_COUNT
        var cpuLoadInfo = host_cpu_load_info_t()
        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) { infoPointer in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { pointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &count)
            }
        }
        if result != KERN_SUCCESS {
            fatalError("Error retrieving CPU load info: \(result)")
        }
        return cpuLoadInfo
    }
    
    // Measure CPU usage
    public static func cpuUsage() -> Float {
        var cpuUsageInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        var usage: Float = 0.0
        
        let result = withUnsafeMutablePointer(to: &cpuUsageInfo) { infoPointer in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { pointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let user = Float(cpuUsageInfo.cpu_ticks.0)
            let system = Float(cpuUsageInfo.cpu_ticks.1)
            let idle = Float(cpuUsageInfo.cpu_ticks.2)
            let total = user + system + idle
            
            if total != 0 {
                usage = (user + system) / total * 100.0
            }
        }
        
        return usage
    }
    
    // Measure GPU usage
    public func gpuUsage() -> Float {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let startTime = CACurrentMediaTime() else {
            return -1.0
        }
        
        // Execute commands
        // Example: render a simple triangle
        let renderPassDescriptor = MTLRenderPassDescriptor()
        // Configure render pass descriptor...
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        // Encode rendering commands...
        renderEncoder.endEncoding()
        
        // Commit command buffer
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // End timing
        guard let endTime = CACurrentMediaTime() else {
            return -1.0
        }
        
        // Calculate GPU usage as a percentage
        let elapsedTime = endTime - startTime
        let baselineTime: Double = 0.001 // Set a baseline time (in seconds) for your Metal commands
        let gpuUsagePercentage = Float(elapsedTime / baselineTime) * 100.0
        
        return gpuUsagePercentage
    }
    
    // Measure RAM usage
    public static func ramUsage() -> Float {
        let taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Float(taskInfo.resident_size) / (1024 * 1024) // Convert bytes to megabytes
        } else {
            return -1
        }
    }
}
