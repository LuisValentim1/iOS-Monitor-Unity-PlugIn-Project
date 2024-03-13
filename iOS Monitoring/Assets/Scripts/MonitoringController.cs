using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class MonitoringController : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField]
    private DataSimulator sim; 
    [SerializeField]
    private Animator animMachine; 
    private Coroutine dataCor;

    [SerializeField]
    private TextMeshProUGUI cpuText;
    [SerializeField]
    private TextMeshProUGUI gpuText;
    [SerializeField]
    private TextMeshProUGUI ramText;

    [SerializeField]
    private GameObject cpuMeter;
    [SerializeField]
    private GameObject gpuMeter;
    [SerializeField]
    private GameObject ramMeter;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void StartMonitoring(){
        animMachine.Play("LightUp", 0);
        dataCor = StartCoroutine(GetData());
    }

    public void StopMonitoring(){
        animMachine.Play("TurnOff", 0);
        StopCoroutine(dataCor);
    }

    public void UpdateUI(float cpuUsagePer, float gpuUsagePer, float ramUsagePer){
        cpuText.GetComponent<TextMeshProUGUI>().text = cpuUsagePer.ToString("F1") + "%";
        cpuMeter.GetComponent<RectTransform>().eulerAngles = new Vector3(0, 0, 180-(1.8f*cpuUsagePer));

        gpuText.GetComponent<TextMeshProUGUI>().text = gpuUsagePer.ToString("F1") + "%";
        gpuMeter.GetComponent<RectTransform>().eulerAngles = new Vector3(0, 0, 180-(1.8f*gpuUsagePer));

        ramText.GetComponent<TextMeshProUGUI>().text = ramUsagePer.ToString("F1") + "%";
        ramMeter.GetComponent<RectTransform>().eulerAngles = new Vector3(0, 0, 180-(1.8f*ramUsagePer));
    }

    IEnumerator GetData(){
        for(;;){

            (float, float) cpuUsage = sim.GetCPUUsage();
            float cpuUsagePercentage = (cpuUsage.Item1 / cpuUsage.Item2) *100;

            (float, float) gpuUsage = sim.GetGPUUsage();
            float gpuUsagePercentage = (gpuUsage.Item1 / gpuUsage.Item2) * 100;

            (float, float) ramUsage = sim.GetRAMUsage();
            float ramUsagePercentage = (ramUsage.Item1 / ramUsage.Item2) * 100;

            UpdateUI(cpuUsagePercentage, gpuUsagePercentage, ramUsagePercentage);
            /**
            curCPUUsage = curCPUUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );
            curGPUUsage = curGPUUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );
            curRAMUsage = curRAMUsage + r.Next(-1, 2) * (varianceFactor +  (float) (r.NextDouble() * (varianceFactor/4)) );
            **/ 

            yield return new WaitForSeconds(0.075f);
        }
    }
}
