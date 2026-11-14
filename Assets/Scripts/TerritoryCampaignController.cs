using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// First playable territory-campaign slice for TIGER CITY 3D.
/// Attach beside CityPrototype and CityBuildController.
/// Creates a central capital, rival regions, recruitable units and a visible
/// greybox battlefield. This is a gameplay prototype, not final art or AI.
/// </summary>
public sealed class TerritoryCampaignController : MonoBehaviour
{
    [Serializable]
    private class RegionSave
    {
        public string id;
        public bool owned;
        public int defenders;
    }

    [Serializable]
    private class CampaignSave
    {
        public int soldiers;
        public int supplies;
        public List<RegionSave> regions = new List<RegionSave>();
    }

    private sealed class Region
    {
        public string id;
        public string title;
        public Vector3 position;
        public int defenders;
        public bool owned;
    }

    [Header("Campaign")]
    [Min(1)] public int startingSoldiers = 24;
    [Min(0)] public int startingSupplies = 100;
    [Min(1)] public int recruitCost = 20;
    [Min(1)] public int recruitBatch = 5;
    [Min(1)] public int battleSupplyCost = 15;

    private readonly List<Region> regions = new List<Region>();
    private readonly List<GameObject> campaignObjects = new List<GameObject>();
    private int soldiers;
    private int supplies;
    private int selectedRegion = -1;
    private string status = "Protect the capital. Scout a neighboring region.";
    private bool battleView;
    private const string SaveKey = "TIGER_CITY_CAMPAIGN_V1";

    private void Start()
    {
        soldiers = startingSoldiers;
        supplies = startingSupplies;
        CreateCampaignMap();
        LoadCampaign();
    }

    private void CreateCampaignMap()
    {
        regions.Clear();
        Vector3 capital = GetCapitalCenter();
        regions.Add(CreateRegion("north", "North District", capital + new Vector3(0, 0, 58), 18, false));
        regions.Add(CreateRegion("east", "Eastern Hills", capital + new Vector3(58, 0, 0), 24, false));
        regions.Add(CreateRegion("south", "Southern Farms", capital + new Vector3(0, 0, -58), 14, false));
        regions.Add(CreateRegion("west", "Western Industrial Zone", capital + new Vector3(-58, 0, 0), 28, false));
        regions.Add(CreateRegion("port", "Coastal Port", capital + new Vector3(42, 0, -42), 32, false));
        BuildRegionMarkers();
    }

    private Vector3 GetCapitalCenter()
    {
        CityPrototype city = GetComponent<CityPrototype>();
        if (city == null) return Vector3.zero;
        float size = city.blocksPerSide * city.blockSize + (city.blocksPerSide + 1) * city.roadWidth;
        return new Vector3(size * 0.5f, 0f, size * 0.5f);
    }

    private Region CreateRegion(string id, string title, Vector3 position, int defenders, bool owned)
    {
        return new Region { id = id, title = title, position = position, defenders = defenders, owned = owned };
    }

    private void BuildRegionMarkers()
    {
        ClearCampaignObjects();
        CreateMarker("Central Capital", GetCapitalCenter(), new Vector3(18, 5, 18), new Color(0.78f, 0.63f, 0.24f));
        foreach (Region region in regions)
        {
            Color color = region.owned ? new Color(0.2f, 0.65f, 0.3f) : new Color(0.65f, 0.22f, 0.18f);
            CreateMarker(region.title, region.position, new Vector3(13, 3, 13), color);
            CreateMarker(region.title + " tower", region.position + Vector3.up * 7f,
                new Vector3(3, 14, 3), color * 0.8f);
        }
    }

    private void CreateMarker(string title, Vector3 position, Vector3 scale, Color color)
    {
        GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cube);
        marker.name = "Campaign " + title;
        marker.transform.SetParent(transform, true);
        marker.transform.position = position + Vector3.up * (scale.y * 0.5f);
        marker.transform.localScale = scale;
        Renderer renderer = marker.GetComponent<Renderer>();
        if (renderer != null)
        {
            Material material = new Material(Shader.Find("Standard"));
            material.color = color;
            renderer.material = material;
        }
        campaignObjects.Add(marker);
    }

    private void ClearCampaignObjects()
    {
        foreach (GameObject item in campaignObjects)
            if (item != null) Destroy(item);
        campaignObjects.Clear();
    }

    private void OnGUI()
    {
        GUI.skin.button.fontSize = 18;
        GUI.skin.label.fontSize = 18;
        GUI.skin.box.fontSize = 20;

        float panelWidth = Mathf.Min(390f, Screen.width * 0.42f);
        GUI.Box(new Rect(12, 116, panelWidth, Screen.height - 250), "CAMPAIGN COMMAND");
        GUI.Label(new Rect(24, 150, panelWidth - 24, 28), "Soldiers: " + soldiers + "   Supplies: " + supplies);

        if (GUI.Button(new Rect(24, 184, panelWidth - 48, 42), "RECRUIT " + recruitBatch + " SOLDIERS  (-" + recruitCost + " supplies)"))
            Recruit();

        float y = 238;
        for (int i = 0; i < regions.Count; i++)
        {
            Region region = regions[i];
            string label = (region.owned ? "[OWNED] " : "[RIVAL] ") + region.title +
                (region.owned ? "" : "  | Def: " + region.defenders);
            if (GUI.Button(new Rect(24, y, panelWidth - 48, 40), label))
            {
                selectedRegion = i;
                battleView = false;
                status = region.owned ? region.title + " is under your control." : "Selected " + region.title + ". Prepare an invasion.";
            }
            y += 46;
        }

        if (selectedRegion >= 0 && selectedRegion < regions.Count)
        {
            Region target = regions[selectedRegion];
            if (!target.owned && GUI.Button(new Rect(24, y + 4, panelWidth - 48, 44), "ATTACK SELECTED REGION"))
                BeginBattle(target);
            if (target.owned && GUI.Button(new Rect(24, y + 4, panelWidth - 48, 44), "REGION SECURED"))
                status = "Maintain supply routes and defend " + target.title + ".";
        }

        GUI.Label(new Rect(24, Screen.height - 82, Screen.width - 48, 34), status);
        if (GUI.Button(new Rect(Screen.width - 150, 18, 138, 42), "SAVE CAMPAIGN"))
            SaveCampaign();
    }

    private void Recruit()
    {
        if (supplies < recruitCost)
        {
            status = "Not enough supplies. Capture or develop supply sources first.";
            return;
        }
        supplies -= recruitCost;
        soldiers += recruitBatch;
        status = recruitBatch + " soldiers joined the capital garrison.";
    }

    private void BeginBattle(Region target)
    {
        if (soldiers < 5)
        {
            status = "Recruit at least 5 soldiers before launching an invasion.";
            return;
        }
        if (supplies < battleSupplyCost)
        {
            status = "Not enough supplies for the invasion. Recruit or secure supplies.";
            return;
        }

        supplies -= battleSupplyCost;
        battleView = true;
        BuildBattlefield(target);
        int committed = Mathf.Min(soldiers, Mathf.Max(5, target.defenders + 3));
        int attackPower = committed + UnityEngine.Random.Range(0, 11);
        int defensePower = target.defenders + UnityEngine.Random.Range(0, 9);

        if (attackPower > defensePower)
        {
            int losses = Mathf.Clamp(defensePower / 3, 1, committed - 1);
            soldiers -= losses;
            target.owned = true;
            target.defenders = 0;
            status = "VICTORY! " + target.title + " captured. Lost " + losses + " soldiers.";
            BuildRegionMarkers();
        }
        else
        {
            int losses = Mathf.Clamp(committed / 3, 1, Mathf.Max(1, soldiers - 1));
            soldiers -= losses;
            target.defenders = Mathf.Max(3, target.defenders - Mathf.Max(1, committed / 4));
            status = "Attack repelled at " + target.title + ". Lost " + losses + " soldiers. Regroup and resupply.";
        }
        SaveCampaign();
    }

    private void BuildBattlefield(Region target)
    {
        ClearCampaignObjects();
        GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
        ground.name = "Battlefield terrain";
        ground.transform.SetParent(transform, true);
        ground.transform.position = new Vector3(0, 0.05f, 0);
        ground.transform.localScale = new Vector3(12, 1, 12);
        Renderer groundRenderer = ground.GetComponent<Renderer>();
        if (groundRenderer != null)
        {
            Material material = new Material(Shader.Find("Standard"));
            material.color = new Color(0.28f, 0.32f, 0.22f);
            groundRenderer.material = material;
        }
        campaignObjects.Add(ground);

        for (int i = 0; i < 7; i++)
        {
            Vector3 position = new Vector3(-22 + i * 7, 1.5f, (i % 2 == 0) ? 10 : -10);
            CreateMarker("Battle cover " + i, position, new Vector3(4, 3, 4),
                new Color(0.38f, 0.36f, 0.3f));
        }

        int friendlyCount = Mathf.Min(12, soldiers);
        int enemyCount = Mathf.Min(12, target.defenders);
        for (int i = 0; i < friendlyCount; i++)
            CreateMarker("Friendly unit " + i, new Vector3(-24 + (i % 6) * 3, 1, -18 + (i / 6) * 5),
                new Vector3(1.2f, 2f, 1.2f), new Color(0.18f, 0.42f, 0.78f));
        for (int i = 0; i < enemyCount; i++)
            CreateMarker("Defender unit " + i, new Vector3(8 + (i % 6) * 3, 1, 12 + (i / 6) * 5),
                new Vector3(1.2f, 2f, 1.2f), new Color(0.72f, 0.2f, 0.16f));

        Camera camera = Camera.main;
        if (camera != null)
        {
            camera.transform.position = new Vector3(0, 62, -70);
            camera.transform.LookAt(Vector3.zero);
        }
    }

    private void SaveCampaign()
    {
        CampaignSave data = new CampaignSave { soldiers = soldiers, supplies = supplies };
        foreach (Region region in regions)
            data.regions.Add(new RegionSave { id = region.id, owned = region.owned, defenders = region.defenders });
        PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(data));
        PlayerPrefs.Save();
        status = "Campaign saved on this device.";
    }

    private void LoadCampaign()
    {
        if (!PlayerPrefs.HasKey(SaveKey)) return;
        CampaignSave data = JsonUtility.FromJson<CampaignSave>(PlayerPrefs.GetString(SaveKey));
        if (data == null) return;
        soldiers = data.soldiers;
        supplies = data.supplies;
        foreach (RegionSave saved in data.regions)
        {
            Region region = regions.Find(r => r.id == saved.id);
            if (region == null) continue;
            region.owned = saved.owned;
            region.defenders = saved.defenders;
        }
        BuildRegionMarkers();
    }
}
