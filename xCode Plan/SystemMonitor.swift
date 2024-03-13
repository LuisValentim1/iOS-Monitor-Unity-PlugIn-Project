import Foundation
import Metal

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
        var thread_info_count: mach_msg_type_number_t
        var threads: thread_act_array_t!
        var thread_info: thread_info_data_t
        var thread_basic_info: thread_basic_info_t
        var thread_stat: thread_extended_info_t
        var task_info: task_info_data_t
        var task_basic_info: task_basic_info_32_t
        var task_extended_info: task_extinfo_data_t
        var task_threads: task_thread_times_info_t?
        var task_thread_count: mach_msg_type_number_t
        var task_thread_info: mach_msg_type_number_t
        var task_cpu_usage: Float = 0
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &task_info, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        task_info_count = mach_msg_type_number_t(TASK_THREAD_TIMES_INFO)
        kr = task_info(mach_task_self_, task_flavor_t(TASK_THREAD_TIMES_INFO), &task_threads, &task_thread_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        task_thread_info = mach_msg_type_number_t(THREAD_INFO_MAX)
        kr = task_threads_info(mach_task_self_, &threads, &task_thread_count, &task_thread_info)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        task_info_count = mach_msg_type_number_t(TASK_THREAD_INFO)
        kr = task_info(threads[0], task_flavor_t(THREAD_BASIC_INFO), &thread_info, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        
        thread_basic_info = thread_info as! thread_basic_info_t
        let taskTotalUserTime = Double(task_threads!.user_time.seconds)
        let taskTotalSystemTime = Double(task_threads!.system_time.seconds)
        let taskTotalTime = taskTotalUserTime + taskTotalSystemTime
        let threadSystemTime = Double(thread_basic_info.pointee.system_time.seconds)
        let threadUserTime = Double(thread_basic_info.pointee.user_time.seconds)
        let threadTime = threadSystemTime + threadUserTime
        let cpuUsage = Float((threadTime / taskTotalTime) * 100)
        
        return cpuUsage
    }
    
    // Measure GPU usage
    public func measureGPUUsage() -> Float {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return -1
        }
        
        // Record rendering commands
        // Example: render a simple triangle
        let renderPassDescriptor = MTLRenderPassDescriptor()
        // Configure render pass descriptor...
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        // Encode rendering commands...
        renderEncoder.endEncoding()
        
        // Measure GPU performance
        let gpuStartTime = CACurrentMediaTime()
        
        // Execute commands
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let gpuEndTime = CACurrentMediaTime()
        let gpuTime = gpuEndTime - gpuStartTime
        
        // Estimate GPU utilization as a percentage
        let totalTimeInterval = gpuEndTime - gpuStartTime
        let utilization = gpuTime / totalTimeInterval
        
        return utilization * 100
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
