import Foundation
import Metal
import QuartzCore

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
    
    // Measure CPU usage
    public static func cpuUsage() -> Float {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        var task_info: task_info_data_t
        var thread_list: thread_act_array_t?
        var thread_count: mach_msg_type_number_t
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &task_info, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        var thread_info: thread_info_data_t = thread_info_data_t.allocate(capacity: Int(THREAD_INFO_MAX))
        
        defer {
            thread_info.deallocate()
        }
        
        var thread_info_count: mach_msg_type_number_t = mach_msg_type_number_t(THREAD_INFO_MAX)
        thread_list = UnsafeMutablePointer.allocate(capacity: Int(task_info.max_threads))
        defer {
            thread_list!.deallocate()
        }
        
        kr = task_threads(mach_task_self_, &thread_list!, &thread_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        var totalUsageOfCPU: Float = 0.0
        
        for i in 0..<Int(thread_count) {
            var threadBasicInfo = thread_basic_info_t.allocate(capacity: 1)
            defer {
                threadBasicInfo.deallocate()
            }
            
            var threadInfoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
            kr = thread_info(thread_list![i], thread_flavor_t(THREAD_BASIC_INFO), threadBasicInfo, &threadInfoCount)
            if kr != KERN_SUCCESS {
                return -1
            }
            
            let threadInfo = threadBasicInfo.pointee
            if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsageOfCPU += Float(threadInfo.cpu_usage) / Float(TH_USAGE_SCALE) * 100.0
            }
        }
        
        return totalUsageOfCPU
    }
    
    // Measure GPU usage
    public func gpuUsage() -> Float {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return -1.0
        }
        
        // Start timing
        let startTime = CACurrentMediaTime()
        
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
        let endTime = CACurrentMediaTime()
        
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
