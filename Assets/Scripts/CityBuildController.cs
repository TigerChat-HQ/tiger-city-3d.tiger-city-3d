using System;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// First playable city-building loop: select a building, tap open ground,
/// spend coins, and save/load the city locally on the device.
/// Attach to the same GameObject as CityPrototype.
/// </summary>
public sealed class CityBuildController : MonoBehaviour
{
    [Serializable]
    private class SavedBuilding
    {
        public float x;
        public float z;
        public int kind;
    }

    [Serializable]
    private class SaveData
    {
        public int coins;
        public List<SavedBuilding> buildings = new List<SavedBuilding>();
    }

    [Header("Gameplay")]
    public int startingCoins = 5000;
    public float snapSize = 2f;
    public LayerMask placementMask = ~0;

    private readonly List<GameObject> placedBuildings = new List<GameObject>();
    private int coins;
    private int selectedKind;
    private Camera gameCamera;
    private const string SaveKey = "TIGER_CITY_3D_SAVE_V1";

    private readonly string[] buildingNames = { "House", "Shop", "Office" };
    private readonly int[] buildingCosts = { 250, 600, 1200 };
    private readonly Vector3[] buildingSizes =
    {
        new Vector3(5f, 4f, 5f),
        new Vector3(6f, 7f, 6f),
        new Vector3(7f, 14f, 7f)
    };
    private readonly Color[] buildingColors =
    {
        new Color(0.78f, 0.68f, 0.52f),
        new Color(0.25f, 0.48f, 0.68f),
        new Color(0.35f, 0.38f, 0.43f)
    };

    private void Start()
    {
        coins = startingCoins;
        gameCamera = Camera.main;
        LoadCity();
    }

    private void Update()
    {
        if (gameCamera == null) gameCamera = Camera.main;
        if (gameCamera == null) return;

        // Unity's legacy mouse input also maps a single-finger Android tap.
        if (Input.GetMouseButtonDown(0) && !IsPointerOverToolbar())
            TryPlaceBuilding(Input.mousePosition);
    }

    private bool IsPointerOverToolbar()
    {
        Vector2 p = Input.mousePosition;
        return p.y < 150f;
    }

    private void TryPlaceBuilding(Vector2 screenPosition)
    {
        Ray ray = gameCamera.ScreenPointToRay(screenPosition);
        RaycastHit hit;
        if (!Physics.Raycast(ray, out hit, 1000f, placementMask)) return;
        if (hit.collider.gameObject.name != "Ground") return;

        int cost = buildingCosts[selectedKind];
        if (coins < cost) return;

        float x = Mathf.Round(hit.point.x / snapSize) * snapSize;
        float z = Mathf.Round(hit.point.z / snapSize) * snapSize;
        Vector3 size = buildingSizes[selectedKind];
        Vector3 position = new Vector3(x, size.y * 0.5f, z);

        Collider[] overlaps = Physics.OverlapBox(position, size * 0.46f);
        foreach (Collider overlap in overlaps)
        {
            if (overlap.gameObject.name != "Ground") return;
        }

        GameObject building = GameObject.CreatePrimitive(PrimitiveType.Cube);
        building.name = buildingNames[selectedKind] + " (Player)";
        building.transform.SetParent(transform, true);
        building.transform.position = position;
        building.transform.localScale = size;

        Renderer renderer = building.GetComponent<Renderer>();
        Material material = new Material(Shader.Find("Standard"));
        material.color = buildingColors[selectedKind];
        renderer.material = material;

        coins -= cost;
        placedBuildings.Add(building);
    }

    private void OnGUI()
    {
        GUI.skin.button.fontSize = 22;
        GUI.skin.label.fontSize = 24;

        GUI.Box(new Rect(12, 12, 250, 48), "TIGER CITY 3D");
        GUI.Label(new Rect(22, 62, 240, 40), "Coins: " + coins);

        float y = Screen.height - 138;
        for (int i = 0; i < buildingNames.Length; i++)
        {
            string label = buildingNames[i] + "  " + buildingCosts[i];
            if (GUI.Button(new Rect(12 + i * 165, y, 155, 52), label))
                selectedKind = i;
        }

        if (GUI.Button(new Rect(12, Screen.height - 74, 145, 52), "SAVE"))
            SaveCity();
        if (GUI.Button(new Rect(167, Screen.height - 74, 145, 52), "LOAD"))
            LoadCity();
    }

    private void SaveCity()
    {
        SaveData data = new SaveData();
        data.coins = coins;
        foreach (GameObject building in placedBuildings)
        {
            if (building == null) continue;
            data.buildings.Add(new SavedBuilding
            {
                x = building.transform.position.x,
                z = building.transform.position.z,
                kind = Mathf.Clamp(Array.IndexOf(buildingNames,
                    building.name.Replace(" (Player)", "")), 0, buildingNames.Length - 1)
            });
        }
        PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(data));
        PlayerPrefs.Save();
    }

    private void LoadCity()
    {
        if (!PlayerPrefs.HasKey(SaveKey)) return;
        SaveData data = JsonUtility.FromJson<SaveData>(PlayerPrefs.GetString(SaveKey));
        if (data == null) return;

        foreach (GameObject building in placedBuildings)
            if (building != null) Destroy(building);
        placedBuildings.Clear();

        coins = data.coins;
        foreach (SavedBuilding saved in data.buildings)
        {
            int kind = Mathf.Clamp(saved.kind, 0, buildingNames.Length - 1);
            Vector3 size = buildingSizes[kind];
            GameObject building = GameObject.CreatePrimitive(PrimitiveType.Cube);
            building.name = buildingNames[kind] + " (Player)";
            building.transform.SetParent(transform, true);
            building.transform.position = new Vector3(saved.x, size.y * 0.5f, saved.z);
            building.transform.localScale = size;
            Material material = new Material(Shader.Find("Standard"));
            material.color = buildingColors[kind];
            building.GetComponent<Renderer>().material = material;
            placedBuildings.Add(building);
        }
    }
}
