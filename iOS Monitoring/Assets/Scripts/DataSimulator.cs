using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DataSimulator : MonoBehaviour
{
    [SerializeField]
    float totalCPU;
    [SerializeField]
    float totalGPU;
    [SerializeField]
    float totalRAM;

    [SerializeField]
    float varianceFactor;

    [SerializeField]
    float curCPUUsage;
    [SerializeField]
    float curGPUUsage;
    [SerializeField]
    float curRAMUsage;

    private System.Random r;

    // Start is called before the first frame update
    void Start()
    {
        r= new System.Random();

        curCPUUsage = (float)((0.6*totalCPU - (0.2*totalCPU)) + (r.NextDouble()*2*(0.2*totalCPU)));
        curGPUUsage = (float)((0.6*totalGPU - (0.2*totalGPU)) + (r.NextDouble()*2*(0.2*totalGPU)));
        curRAMUsage = (float)((0.6*totalRAM - (0.2*totalRAM)) + (r.NextDouble()*2*(0.2*totalRAM)));

        StartCoroutine(GenerateData());
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public (float,float) GetCPUUsage(){
        return (curCPUUsage, totalCPU);
    }

    public (float,float) GetGPUUsage(){
        return (curGPUUsage, totalGPU);
    }

    public (float,float) GetRAMUsage(){
        return (curRAMUsage, totalRAM);
    }

    IEnumerator GenerateData(){
        for(;;){
            curCPUUsage = curCPUUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );
            curGPUUsage = curGPUUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );
            curRAMUsage = curRAMUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );

            yield return new WaitForSeconds(0.075f);
        }
    }

}
