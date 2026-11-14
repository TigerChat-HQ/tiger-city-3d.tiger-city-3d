using UnityEngine;

/// <summary>
/// Runtime entry point for the first prototype scene. It attaches the
/// greybox city and campaign systems to the scene root.
/// </summary>
[DisallowMultipleComponent]
public sealed class TigerCityBootstrap : MonoBehaviour
{
    private void Awake()
    {
        if (GetComponent<CityPrototype>() == null) gameObject.AddComponent<CityPrototype>();
        if (GetComponent<CityBuildController>() == null) gameObject.AddComponent<CityBuildController>();
        if (GetComponent<TerritoryCampaignController>() == null) gameObject.AddComponent<TerritoryCampaignController>();
    }
}
