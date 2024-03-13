using System.Runtime.InteropServices;
using UnityEngine;

public class SystemMonitorExample : MonoBehaviour
{
    [DllImport("__Internal")]
    private static extern float cpuUsage();

    [DllImport("__Internal")]
    private static extern float gpuUsage();

    [DllImport("__Internal")]
    private static extern float ramUsage();

    void Start()
    {
        // Call the CPU usage function
        float cpu = cpuUsage();
        Debug.Log("CPU Usage: " + cpu + "%");

        // Call the GPU usage function
        float gpu = gpuUsage();
        Debug.Log("GPU Usage: " + gpu + "%");

        // Call the RAM usage function
        float ram = ramUsage();
        Debug.Log("RAM Usage: " + ram + " MB");
    }
}
